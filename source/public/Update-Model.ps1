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

    function compress {
        param (
            $Content
        )

        $Child = Get-ChildItem $Content

        Compress-Archive -Path $Child -DestinationPath $Content\DriverPackage.zip -PassThru

    }

    function path_creator {
        param (
            $Parent,
            $Array
        )

        $Path =  Join-Path $Parent ($Array -join '\')

        if (-not (Test-Path $Path)) {
            New-Item $Path -ItemType Directory -ErrorAction SilentlyContinue
            return
        }

        [io.directoryinfo] $Path
    }

    function connect {
        param (
            $SiteCode,
            $SiteServerFQDN
        )
        
        try {
            Import-Module (Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH -Parent) 'ConfigurationManager.psd1')
        } catch {
            throw 'The specified module ''ConfigurationManager'' was not loaded because no valid module file was found. Is the admin console installed?'
        }

        if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServerFQDN -Description "SCCM Site" | Out-Null
        }

    }

    function check_site {
        param (
            $Package
        )

        Push-Location ('{0}:' -f $SiteCode)

        Get-CMPackage -Name $Package.Name -Fast | Where-Object Version -EQ $Package.Version
        
        Pop-Location
    }

    function clean_temp {
        Get-ChildItem -Path $WorkingDir | Remove-Item -Recurse -Force
    }

    function Log() {
        $input | ForEach-Object {
            if (-not $NoHostOutput) { Write-Host $_ }
        }
    }

    if (-not $WorkingDir) {
        $WorkingDir = path_creator $env:TEMP 'OpenDriverTool'
    }

    "Updating $Make $Model" | Log

    path_creator $WorkingDir 'Content' | Out-Null
    
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

    connect $SiteCode $SiteServerFQDN

    if (-not (check_site $DriverPackage) -and $Driver) {

        "`n  Driver version not found in configmgr" | Log
        
        '    Downloading: {0}' -f $Driver.path  | Log
        $DriverFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $Driver.path) -Destination $WorkingDir -Hash $Drivers.hashMD5 -Algorithm MD5

        '    Extracting: {0}' -f $DriverFile.FullName| Log
        $ExtractedContent = Expand-Drivers -Make $Make -Path $DriverFile -Destination $WorkingDir

        '    Compressing driver package.'
        $Archive = compress $ExtractedContent

        $DriverPath = (
            $Make,
            $Model,
            'Driver',
            $OSVersion,
            $Driver.dellVersion
        )

        $DriverContent = path_creator $ContentShare $DriverPath

        Copy-Item -Path $Archive -Destination $DriverContent


        '    Creating driver package in sccm.'
        New-Package -Package $DriverPackage -Type 'Driver' -SiteCode $SiteCode -ContentPath $DriverContent -DistributionPoints $DistributionPoints -Make $Make
    } else {
        '  Latest driver already in confimgr.' | Log
    }

    if (-not (check_site $BIOSPackage) -and $BIOS) {

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

        $BIOSContent = path_creator $ContentShare $BIOSPath

        Copy-Item -Path $BIOSFile -Destination $BIOSContent
        Copy-Item -Path $Flash64Extract -Destination $BIOSContent

        '    Creating bios package in sccm.'
        New-Package -Package $BIOSPackage -Type 'BIOS' -SiteCode $SiteCode -ContentPath $BIOSContent -DistributionPoints $DistributionPoints -Make $Make
    } else {
        '  Latest bios already in configmgr.' | Log
    }

    clean_temp
}
