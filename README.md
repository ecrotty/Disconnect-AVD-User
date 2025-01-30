# Disconnect-User-AVD

A PowerShell script for disconnecting users from Azure Virtual Desktop (AVD) host pools. This script provides a simple and efficient way to manage user sessions in AVD environments.

## Features

- Automatically checks and installs required Azure PowerShell modules
- Verifies Azure connection status
- Disconnects specified user from all sessions in a host pool
- Provides detailed feedback and error handling
- Cross-platform compatibility (Windows, macOS, Linux)

## Prerequisites

- PowerShell 5.1 or higher
- Azure PowerShell modules (automatically installed if missing)
- Active Azure connection

## Installation

1. Clone the repository:
```powershell
git clone https://github.com/ecrotty/Disconnect-User-AVD.git
```

2. Navigate to the script directory:
```powershell
cd Disconnect-User-AVD
```

## Usage

```powershell
.\Disconnect-UserAVD.ps1 -UserPrincipalName "user@domain.com" -HostPoolName "YourHostPool" -ResourceGroupName "YourResourceGroup"
```

### Parameters

- `UserPrincipalName`: The user's email address/UPN to disconnect
- `HostPoolName`: The name of the AVD host pool
- `ResourceGroupName`: The name of the Azure resource group containing the host pool
- `Help`: Display help information

### Example

```powershell
.\Disconnect-UserAVD.ps1 -UserPrincipalName "john.doe@company.com" -HostPoolName "prod-hostpool-01" -ResourceGroupName "rg-avd-prod-01"
```

To display help information:
```powershell
.\Disconnect-UserAVD.ps1 -Help
```

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on how to submit pull requests, report issues, and contribute to the project.

## License

This project is licensed under the BSD License - see the [LICENSE](LICENSE) file for details.

## Author

Edward Crotty
- GitHub: [ecrotty](https://github.com/ecrotty)

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/ecrotty/Disconnect-User-AVD/issues) on GitHub.
