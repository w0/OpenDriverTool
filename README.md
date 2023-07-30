[![version](https://img.shields.io/powershellgallery/v/OpenDriverTool)](https://www.powershellgallery.com/packages/OpenDriverTool)
[![downloads](https://img.shields.io/powershellgallery/dt/OpenDriverTool)](https://www.powershellgallery.com/packages/OpenDriverTool)
[![license](https://img.shields.io/github/license/w0/OpenDriverTool)](https://github.com/w0/OpenDriverTool/blob/127920655f89888a3fe9f3f44273dd7809f6b503/LICENSE)

# Open Driver Tool

A powershell module to help create driver and bios update packges in Microsoft's Configuration Manager.

## Installation

To install the module from the [PowerShell Gallery](https://www.powershellgallery.com/):

```powershell
Install-Module -Name OpenDriverTool -Repository PSGallery
```

## Usage

For detailed usage information see the provided documentation, or use the `Get-Help` cmdlet. 

```powershell
Import-Module -Name OpenDriverTool

$Splat = @{
    Make               = 'Dell'
    Model              = 'Latitude 5420'
    ContentShare       = '\\configmgrnetworkshare\Drivers'
    SiteCode           = 'ABC'
    SiteServerFQDN     = 'abc.contoso.com'
    DistributionPoints = @('abc.contoso.com', 'abc2.contoso.com')
} 

Update-Model @Splat -OSVersion 'Windows 11'
```

## Build

#### 1. Clone this repo

```powershell
git clone https://github.com/w0/OpenDriverTool.git
cd OpenDriverTool
```

### 2. Run the build script
The build script will install any required modules needed and automatically import the module.

```powershell 
./build.ps1
```