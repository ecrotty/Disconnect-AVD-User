# Author: Edward Crotty
# GitHub: https://github.com/ecrotty/Disconnect-User-AVD
# License: BSD License

<#
.SYNOPSIS
    Disconnects a user from an Azure Virtual Desktop (AVD) host pool.

.DESCRIPTION
    This script disconnects a specified user from an Azure Virtual Desktop host pool. It performs the following:
    - Verifies and installs required Azure PowerShell module (Az.DesktopVirtualization)
    - Checks Azure connection status
    - Finds and disconnects all active sessions for the specified user in the given host pool
    - Provides detailed feedback on all operations

.PARAMETER UserPrincipalName
    The user principal name (email) of the user to disconnect
    Example: user@domain.com

.PARAMETER HostPoolName
    The name of the AVD host pool
    Example: "prod-hostpool-01"

.PARAMETER ResourceGroupName
    The name of the Azure resource group containing the host pool
    Example: "rg-avd-prod-01"

.PARAMETER Help
    Displays this help message

.EXAMPLE
    .\Disconnect-UserAVD.ps1 -UserPrincipalName "user@domain.com" -HostPoolName "prod-hostpool-01" -ResourceGroupName "rg-avd-prod-01"

.NOTES
    Prerequisites:
    - PowerShell 5.1 or higher
    - Azure PowerShell module (Az.DesktopVirtualization) (will be automatically installed if missing)
    - Active Azure connection (use Connect-AzAccount if not connected)
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory = $false)]
    [string]$HostPoolName,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

# Display help message if -Help is used
if ($Help) {
    Write-Host @"
Disconnect-UserAVD.ps1 - Disconnects a user from an Azure Virtual Desktop (AVD) host pool

SYNTAX
    .\Disconnect-UserAVD.ps1 -UserPrincipalName <String> -HostPoolName <String> -ResourceGroupName <String> [-Help]

PARAMETERS
    -UserPrincipalName <String>
        The user principal name (email) of the user to disconnect
        Example: user@domain.com
        Required: Yes

    -HostPoolName <String>
        The name of the AVD host pool
        Example: prod-hostpool-01
        Required: Yes

    -ResourceGroupName <String>
        The name of the Azure resource group containing the host pool
        Example: rg-avd-prod-01
        Required: Yes

    -Help [switch]
        Displays this help message

EXAMPLE
    .\Disconnect-UserAVD.ps1 -UserPrincipalName "user@domain.com" -HostPoolName "prod-hostpool-01" -ResourceGroupName "rg-avd-prod-01"

NOTES
    - Requires PowerShell 5.1 or higher
    - Required module (Az.DesktopVirtualization) will be automatically installed if missing
    - Must be connected to Azure (use Connect-AzAccount if not connected)
"@
    exit 0
}

# Verify required parameters if not displaying help
if (-not $UserPrincipalName -or -not $HostPoolName -or -not $ResourceGroupName) {
    Write-Error "Missing required parameters. Use -Help for usage information."
    exit 1
}

function Test-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    
    if (!(Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "Module '$ModuleName' is not installed. Installing now..." -ForegroundColor Yellow
        try {
            Install-Module -Name $ModuleName -Force -AllowClobber -Scope CurrentUser
            Write-Host "Successfully installed module '$ModuleName'" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install module '$ModuleName': $($_.Exception.Message)"
            return $false
        }
    }
    return $true
}

# Main script execution
try {
    # Check and install required module
    if (!(Test-ModuleInstalled -ModuleName "Az.DesktopVirtualization")) {
        throw "Required module installation failed"
    }

    # Import module
    Import-Module Az.DesktopVirtualization

    # Simple connection check
    try {
        $null = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $HostPoolName -ErrorAction Stop
        Write-Host "Successfully connected to Azure and verified host pool access" -ForegroundColor Green
    }
    catch {
        throw "Failed to access Azure resources. Please ensure you're connected (Connect-AzAccount) and have proper permissions."
    }

    # Get all session hosts in the host pool
    Write-Host "Getting session hosts for host pool $HostPoolName..." -ForegroundColor Yellow
    $sessionHosts = Get-AzWvdSessionHost -HostPoolName $HostPoolName -ResourceGroupName $ResourceGroupName
    $foundSessions = $false

    foreach ($sessionHost in $sessionHosts) {
        # Extract the session host name from the full resource ID
        $sessionHostName = $sessionHost.Name.Split('/')[-1]
        Write-Host "Checking sessions on host $sessionHostName..." -ForegroundColor Yellow
        
        try {
            # Get user sessions for this session host
            $sessions = Get-AzWvdUserSession -HostPoolName $HostPoolName `
                                           -ResourceGroupName $ResourceGroupName `
                                           -SessionHostName $sessionHostName

            Write-Host "Found $($sessions.Count) total sessions on host $sessionHostName" -ForegroundColor Gray
            
            $userSessions = $sessions | Where-Object { $_.UserPrincipalName -eq $UserPrincipalName }

            if ($userSessions) {
                $foundSessions = $true
                foreach ($session in $userSessions) {
                    Write-Host "Found active session for $UserPrincipalName on host $sessionHostName" -ForegroundColor Yellow
                    Write-Host "Session details:" -ForegroundColor Yellow
                    Write-Host "  Session ID: $($session.Name)" -ForegroundColor Gray
                    Write-Host "  Session State: $($session.SessionState)" -ForegroundColor Gray
                    
                    try {
                        Write-Host "Attempting to disconnect session..." -ForegroundColor Yellow
                        
                        Remove-AzWvdUserSession -HostPoolName $HostPoolName `
                                              -ResourceGroupName $ResourceGroupName `
                                              -SessionHostName $sessionHostName `
                                              -Id $session.Name `
                                              -Force -ErrorAction Stop

                        Write-Host "Successfully disconnected session for user $UserPrincipalName on host $sessionHostName" -ForegroundColor Green
                    }
                    catch {
                        Write-Error "Failed to disconnect session: $($_.Exception.Message)"
                        Write-Host "Attempting alternative disconnect method..." -ForegroundColor Yellow
                        
                        # Alternative method using session ID format
                        $sessionId = $session.Name.Split('/')[-1]
                        Remove-AzWvdUserSession -HostPoolName $HostPoolName `
                                              -ResourceGroupName $ResourceGroupName `
                                              -SessionHostName $sessionHostName `
                                              -Id $sessionId `
                                              -Force
                                              
                        Write-Host "Successfully disconnected session using alternative method" -ForegroundColor Green
                    }
                }
            }
            else {
                Write-Host "No sessions found for $UserPrincipalName on host $sessionHostName" -ForegroundColor Gray
            }
        }
        catch {
            Write-Error "Error processing host $sessionHostName`: $($_.Exception.Message)"
        }
    }

    if (-not $foundSessions) {
        Write-Host "No active sessions found for user $UserPrincipalName in host pool $HostPoolName" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}
