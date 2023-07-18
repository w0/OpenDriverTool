function Update-DellDriver {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [string]
        $Model,

        [Parameter(Mandatory)]
        [ValidateSet('Windows 10', 'Windows 11')]
        [string]
        $OSVersion,

        [Parameter()]
        [io.directoryInfo]
        $WorkingDir,

        [Parameter(Mandatory)]
        [io.directoryInfo]
        $ContentShare,

        [Parameter(Mandatory)]
        [string]
        $SiteCode,

        [Parameter(Mandatory)]
        [string]
        $SiteServerFQDN,

        [Parameter(Mandatory)]
        [string[]]
        $DistributionPoints
    )

    if (-not $WorkingDir) {
        $WorkingDir = Path-Creator -Parent $env:TEMP -Child 'OpenDriverTool'
    }

    "Updating drivers for Dell $Model" | Log

    Path-Creator -Parent $WorkingDir -Child 'Content' | Out-Null
    
    $DellCatalog = Get-DellCatalog

    $DriverPackCatalogUrl = $DellCatalog.Where( {$_.Filename -eq 'DriverPackCatalog.CAB'}, 'First' )

    '  Getting Dell cabinet files...' | Log
    '    Downloading: {0}' -f $DriverPackCatalogUrl.Url | Log
    $DriverPackCatalogCAB = $DriverPackCatalogUrl.Url | Get-RemoteFile -Destination $WorkingDir

    Expand-Cab -Path $DriverPackCatalogCAB -Destination $WorkingDir\Content

    [xml] $DriverPackCatalog = Get-Content -Path "$WorkingDir\Content\DriverPackCatalog.xml"

    $Driver = Find-DellDrivers -DriverPackCatalog $DriverPackCatalog -Model $Model -OSVersion ($OSVersion -replace '\s', '')
    '  Found Driver: {0}' -f $Driver.path | Log

    $DriverPackage = @{
        Name = 'Drivers - {0} {1} - {2} {3}' -f 'Dell', $Model, $OSVersion, $Driver.SupportedOperatingSystems.OperatingSystem.osArch
        Version = $Driver.dellVersion
        Manufacturer = 'Dell'
        Description = '(Models included:{0})' -f ($Driver.SupportedSystems.brand.model.systemID -join ';')
    }

    Connect-SCCM -SiteCode $SiteCode -SiteServerFQDN $SiteServerFQDN

    if (-not (Confirm-ExistingPackage -Package $DriverPackage -SiteCode $SiteCode) -and $Driver) {

        "`n  Driver version not found in configmgr" | Log
        
        '    Downloading: {0}' -f $Driver.path  | Log
        $DriverFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $Driver.path) -Destination $WorkingDir -Hash $Drivers.hashMD5 -Algorithm MD5

        '    Extracting: {0}' -f $DriverFile.FullName| Log
        $ExtractedContent = Expand-Drivers -Make 'Dell' -Path $DriverFile -Destination $WorkingDir

        '    Compressing driver package.'
        $Archive = Compress-Drivers -ContentPath $ExtractedContent

        $DriverPath = (
            'Dell',
            $Model,
            'Driver',
            $OSVersion,
            $Driver.dellVersion
        )

        $DriverContent = Path-Creator -Parent $ContentShare -Child $DriverPath

        Copy-Item -Path $Archive -Destination $DriverContent


        '    Creating driver package in sccm.'
        New-Package -Package $DriverPackage -Type 'Driver' -SiteCode $SiteCode -ContentPath $DriverContent -DistributionPoints $DistributionPoints -Make 'Dell'
    } else {
        '  Latest driver already in confimgr.' | Log
    }
}
