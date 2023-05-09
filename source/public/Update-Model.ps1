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

    function extract {
        param (
            $DriverFile
        )

        $ExtractDir = Join-Path $WorkingDir (New-Guid).Guid

        New-Item $ExtractDir -ItemType Directory -ErrorAction Stop | Out-Null

        switch ($DriverFile.Extension) {
            '.exe' {
                Start-Process -FilePath $DriverFile -ArgumentList ('/s /e="{0}"' -f $ExtractDir) -Wait; break
            }
            '.cab' {
                Expand-Cab -Path $DriverFile -Destination $ExtractDir; break
            }
            default { throw 'unhandled file extension {0}. unable to extract drivers.' -f $_ }
        }

        $ExtractDir

    }

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
        Remove-Item -Path $ExtractedContent -Recurse -Force
        Remove-Item -Path $DriverFile -Force
        Remove-Item -Path (Split-Path $Flash64Extract -Parent) -Recurse -Force
        Remove-Item -Path $BIOSFile -Force
    }

    if (-not $WorkingDir) {
        $WorkingDir = path_creator $env:TEMP 'OpenDriverTool'
    }

    path_creator $WorkingDir 'Content' | Out-Null
    
    $DellCatalog = Get-DellCatalog

    $DriverPackCatalogUrl = $DellCatalog.Where( {$_.Filename -eq 'DriverPackCatalog.CAB'}, 'First' )
    $CatalogPCUrl      = $DellCatalog.Where( { $_.Filename -eq 'CatalogPC.cab'}, 'First' )
    
    $DriverPackCatalogCAB = $DriverPackCatalogUrl.Url | Get-RemoteFile -Destination $WorkingDir

    $CatalogPCCAB = $CatalogPCUrl.Url | Get-RemoteFile -Destination $WorkingDir

    Expand-Cab -Path $DriverPackCatalogCAB -Destination $WorkingDir\Content
    Expand-Cab -Path $CatalogPCCAB -Destination $WorkingDir\Content

    [xml] $DriverPackCatalog = Get-Content -Path "$WorkingDir\Content\DriverPackCatalog.xml"
    [xml] $CatalogPC = Get-Content -Path "$WorkingDir\Content\CatalogPC.xml"

    $Driver = Find-DellDrivers -DriverPackCatalog $DriverPackCatalog -Model $Model -OSVersion ($OSVersion -replace '\s', '')

    $BIOS = Find-DellBIOS -Model $Model -DriverPackCatalog $DriverPackCatalog -CatalogPC $CatalogPC

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

    if (-not (check_site $DriverPackage)) {
        $DriverFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $Driver.path) -Destination $WorkingDir -Hash $Drivers.hashMD5 -Algorithm MD5

        $ExtractedContent = extract $DriverFile

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

        New-Package -Package $DriverPackage -Type 'Driver' -SiteCode $SiteCode -ContentPath $DriverContent -DistributionPoints $DistributionPoints -Make $Make
    }

    if (-not (check_site $BIOSPackage)) {

        $BIOSFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $BIOS.path) -Destination $WorkingDir -Hash $BIOS.hashMD5 -Algorithm MD5
        $Flash64Zip = Get-RemoteFile -Url 'https://downloads.dell.com/FOLDER08405216M/1/Ver3.3.16.zip' -Destination $WorkingDir

        $Flash64Extract = Expand-Archive -Path $Flash64Zip -DestinationPath $WorkingDir -PassThru | Where-Object Name -eq 'Flash64W.exe'

        $BIOSPath = (
            $Make,
            $Model,
            'BIOS',
            $BIOS.dellVersion
        )

        $BIOSContent = path_creator $ContentShare $BIOSPath

        Copy-Item -Path $BIOSFile -Destination $BIOSContent
        Copy-Item -Path $Flash64Extract -Destination $BIOSContent

        New-Package -Package $BIOSPackage -Type 'BIOS' -SiteCode $SiteCode -ContentPath $DriverContent -DistributionPoints $DistributionPoints -Make $Make
    }

    clean_temp
}
