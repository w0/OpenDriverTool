function Update-Model {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [ValidateSet('Dell')]
        [string]
        $Make,

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

    "Updating $Make $Model" | Log

    Path-Creator -Parent $WorkingDir -Child 'Content' | Out-Null
    
    $DellCatalog = Get-DellCatalog

    $DriverPackCatalogUrl = $DellCatalog.Where( {$_.Filename -eq 'DriverPackCatalog.CAB'}, 'First' )
    $CatalogPCUrl      = $DellCatalog.Where( { $_.Filename -eq 'CatalogPC.cab'}, 'First' )
    

    '  Getting Dell cabinet files...' | Log
    '    Downloading: {0}' -f $DriverPackCatalogUrl.Url | Log
    $DriverPackCatalogCAB = $DriverPackCatalogUrl.Url | Get-RemoteFile -Destination $WorkingDir

    '    Downloading: {0}' -f $CatalogPCUrl.Url | Log
    $CatalogPCCAB = $CatalogPCUrl.Url | Get-RemoteFile -Destination $WorkingDir

    Expand-Cab -Path $DriverPackCatalogCAB -Destination $WorkingDir\Content
    Expand-Cab -Path $CatalogPCCAB -Destination $WorkingDir\Content

    [xml] $DriverPackCatalog = Get-Content -Path "$WorkingDir\Content\DriverPackCatalog.xml"
    [xml] $CatalogPC = Get-Content -Path "$WorkingDir\Content\CatalogPC.xml"

    $Driver = Find-DellDrivers -DriverPackCatalog $DriverPackCatalog -Model $Model -OSVersion ($OSVersion -replace '\s', '')
    '  Found Driver: {0}' -f $Driver.path| Log

    $BIOS = Find-DellBIOS -Model $Model -DriverPackCatalog $DriverPackCatalog -CatalogPC $CatalogPC
    '  Found BIOS: {0}' -f $BIOS.path | Log

    $DriverPackage = @{
        Name = 'Drivers - {0} {1} - {2} {3}' -f $Make, $Model, $OSVersion, $Driver.SupportedOperatingSystems.OperatingSystem.osArch
        Version = $Driver.dellVersion
        Manufacturer = $Make
        Description = '(Models included:{0})' -f ($Driver.SupportedSystems.brand.model.systemID -join ';')
    }

    $BIOSPackage = @{
        Name = 'BIOS Update - {0} {1}' -f $Make, $Model
        Manufacturer = $Make
        Version = $BIOS.dellVersion
        Description = '(Models included:{0})' -f ($BIOS.SupportedSystems.Brand.Model.systemID -join ';')
    }

    Connect-SCCM -SiteCode $SiteCode -SiteServerFQDN $SiteServerFQDN

    if (-not (Confirm-ExistingPackage -Package $DriverPackage -SiteCode $SiteCode) -and $Driver) {

        "`n  Driver version not found in configmgr" | Log
        
        '    Downloading: {0}' -f $Driver.path  | Log
        $DriverFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $Driver.path) -Destination $WorkingDir -Hash $Drivers.hashMD5 -Algorithm MD5

        '    Extracting: {0}' -f $DriverFile.FullName| Log
        $ExtractedContent = Expand-Drivers -Make $Make -Path $DriverFile -Destination $WorkingDir

        '    Compressing driver package.'
        $Archive = Compress-Drivers -ContentPath $ExtractedContent

        $DriverPath = (
            $Make,
            $Model,
            'Driver',
            $OSVersion,
            $Driver.dellVersion
        )

        $DriverContent = Path-Creator -Parent $ContentShare -Child $DriverPath

        Copy-Item -Path $Archive -Destination $DriverContent


        '    Creating driver package in sccm.'
        New-Package -Package $DriverPackage -Type 'Driver' -SiteCode $SiteCode -ContentPath $DriverContent -DistributionPoints $DistributionPoints -Make $Make
    } else {
        '  Latest driver already in confimgr.' | Log
    }

    if (-not (Confirm-ExistingPackage -Package $BIOSPackage -SiteCode $SiteCode) -and $BIOS) {

        $Flash64Url = 'https://downloads.dell.com/FOLDER08405216M/1/Ver3.3.16.zip'

        "`n  BIOS version not found in configmgr" | Log

        '    Downloading: {0}' -f $BIOS.path | Log
        $BIOSFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $BIOS.path) -Destination $WorkingDir -Hash $BIOS.hashMD5 -Algorithm MD5

        '    Downloading: {0}' -f $Flash64Url | Log
        $Flash64Zip = Get-RemoteFile -Url $Flash64Url -Destination $WorkingDir

        $Flash64Extract = Expand-Archive -Path $Flash64Zip -DestinationPath $WorkingDir -Force -PassThru | Where-Object Name -eq 'Flash64W.exe'

        $BIOSPath = (
            $Make,
            $Model,
            'BIOS',
            $BIOS.dellVersion
        )

        $BIOSContent = Path-Creator -Parent $ContentShare -Child $BIOSPath

        Copy-Item -Path $BIOSFile -Destination $BIOSContent
        Copy-Item -Path $Flash64Extract -Destination $BIOSContent

        '    Creating bios package in sccm.'
        New-Package -Package $BIOSPackage -Type 'BIOS' -SiteCode $SiteCode -ContentPath $BIOSContent -DistributionPoints $DistributionPoints -Make $Make
    } else {
        '  Latest bios already in configmgr.' | Log
    }

    Clean-Temp -Path $WorkingDir
}
