function Update-DellBios {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [string]
        $Model,

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

        [Parameter(Mandatory, ParameterSetName = 'DistributionPoints')]
        [Parameter(Mandatory, ParameterSetName = 'PointAndGroup')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DistributionPoints,

        [Parameter(Mandatory, ParameterSetName = 'DistributionPointGroups')]
        [Parameter(Mandatory, ParameterSetName = 'PointAndGroup')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DistributionPointGroups
    )

    if (-not $WorkingDir) {
        $WorkingDir = Path-Creator -Parent $env:TEMP -Child 'OpenDriverTool'
    }

    "Updating Bios for Dell $Model" | Log

    Path-Creator -Parent $WorkingDir -Child 'Content' | Out-Null

    $DriverPackCatalogUrl = 'https://downloads.dell.com/catalog/DriverPackCatalog.CAB'
    $CatalogPCUrl         = 'https://downloads.dell.com/catalog/CatalogPC.cab'
    

    '  Getting Dell cabinet files...' | Log
    '    Downloading: {0}' -f $DriverPackCatalogUrl | Log
    $DriverPackCatalogCAB = $DriverPackCatalogUrl | Get-RemoteFile -Destination $WorkingDir

    '    Downloading: {0}' -f $CatalogPCUrl | Log
    $CatalogPCCAB = $CatalogPCUrl | Get-RemoteFile -Destination $WorkingDir

    Expand-Cab -Path $DriverPackCatalogCAB -Destination $WorkingDir\Content
    Expand-Cab -Path $CatalogPCCAB -Destination $WorkingDir\Content

    [xml] $DriverPackCatalog = Get-Content -Path "$WorkingDir\Content\DriverPackCatalog.xml"
    [xml] $CatalogPC = Get-Content -Path "$WorkingDir\Content\CatalogPC.xml"

    $BIOS = Find-DellBIOS -Model $Model -DriverPackCatalog $DriverPackCatalog -CatalogPC $CatalogPC
    '  Found BIOS: {0}' -f $BIOS.path | Log

    $BIOSPackage = @{
        Name = 'BIOS Update - {0} {1}' -f 'Dell', $Model
        Manufacturer = 'Dell'
        Version = $BIOS.dellVersion
        Description = '(Models included:{0})' -f ($BIOS.SupportedSystems.Brand.Model.systemID -join ';')
    }

    Connect-SCCM -SiteCode $SiteCode -SiteServerFQDN $SiteServerFQDN

    if (-not (Confirm-ExistingPackage -Package $BIOSPackage -SiteCode $SiteCode) -and $BIOS) {

        $Flash64Url = 'https://downloads.dell.com/FOLDER08405216M/1/Ver3.3.16.zip'

        "`n  BIOS version not found in configmgr" | Log

        '    Downloading: {0}' -f $BIOS.path | Log
        $BIOSFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $BIOS.path) -Destination $WorkingDir -Hash $BIOS.hashMD5 -Algorithm MD5

        '    Downloading: {0}' -f $Flash64Url | Log
        $Flash64Zip = Get-RemoteFile -Url $Flash64Url -Destination $WorkingDir

        $Flash64Extract = Expand-Archive -Path $Flash64Zip -DestinationPath $WorkingDir -Force -PassThru | Where-Object Name -eq 'Flash64W.exe'

        $BIOSPath = (
            'Dell',
            $Model,
            'BIOS',
            $BIOS.dellVersion
        )

        $BIOSContent = Path-Creator -Parent $ContentShare -Child $BIOSPath

        Copy-Item -Path $BIOSFile -Destination $BIOSContent
        Copy-Item -Path $Flash64Extract -Destination $BIOSContent

        '    Creating bios package in sccm.'
        $CMPackage = New-Package -Package $BIOSPackage -Type 'BIOS' -SiteCode $SiteCode -ContentPath $BIOSContent -Make $Make

        switch ($PSBoundParameters.Keys) {
            'DistributionPoints'      { Start-ContentDistribution -CMPackage $CMPackage -SiteCode $SiteCode -DistributionPoints $DistributionPoints }
            'DistributionPointGroups' { Start-ContentDistribution -CMPackage $CMPackage -SiteCode $SiteCode -DistributionPointGroups $DistributionPointGroups }
        }

    } else {
        '  Latest bios already in configmgr.' | Log
    }
}
