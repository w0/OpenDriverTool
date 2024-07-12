function Update-DellBios {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [string]
        $Model,

        [Parameter()]
        [io.directoryInfo]
        $WorkingDir,

        [Parameter(Mandatory, ParameterSetName = 'DownloadOnly')]
        [Parameter(Mandatory, ParameterSetName = 'DistributionPointGroups')]
        [Parameter(Mandatory, ParameterSetName = 'DistributionPoints')]
        [Parameter(Mandatory, ParameterSetName = 'PointAndGroup')]
        [Alias('Destination')]
        [io.directoryInfo]
        $ContentShare,

        [Parameter(Mandatory, ParameterSetName = 'DistributionPointGroups')]
        [Parameter(Mandatory, ParameterSetName = 'DistributionPoints')]
        [Parameter(Mandatory, ParameterSetName = 'PointAndGroup')]
        [string]
        $SiteCode,

        [Parameter(Mandatory, ParameterSetName = 'DistributionPointGroups')]
        [Parameter(Mandatory, ParameterSetName = 'DistributionPoints')]
        [Parameter(Mandatory, ParameterSetName = 'PointAndGroup')]
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
        $DistributionPointGroups,
        
        [Parameter(Mandatory, ParameterSetName = 'DownloadOnly')]
        [switch]
        $DownloadOnly
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

    if (-not $BIOS) {
        Write-Error -Message "Failed to find BIOS. Please verify the name of your model is correct." -ErrorAction Stop
    }

    '  Found BIOS: {0}' -f $BIOS.path | Log

    $BIOSPackage = @{
        Name = 'BIOS Update - {0} {1}' -f 'Dell', $Model
        Manufacturer = 'Dell'
        Version = $BIOS.dellVersion
        Description = '(Models included:{0})' -f ($BIOS.SupportedSystems.Brand.Model.systemID -join ';')
    }

    if ($PSCmdlet.ParameterSetName -ne 'DownloadOnly') {
        Connect-SCCM -SiteCode $SiteCode -SiteServerFQDN $SiteServerFQDN
        $ExistingPackage = Confirm-ExistingPackage -Package $BIOSPackage -SiteCode $SiteCode
    }

    if ($ExistingPackage) {
        '  Latest driver already in configmgr.' | Log
        return
    }

    if ($PSCmdlet.ParameterSetName -ne 'DownloadOnly') {

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

    }

    if ($PSCmdlet.ParameterSetName -eq 'DownloadOnly') {
        if (-not (Test-Path $ContentShare)) {
            New-Item -Path $ContentShare -ItemType Directory | Out-Null
        }

        '    Downloading: {0}' -f $BIOS.path | Log
        $BIOSFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $BIOS.path) -Destination $ContentShare -Hash $BIOS.hashMD5 -Algorithm MD5

        '  Downloaded: {0}' -f $BIOSFile.FullName | Log
    }
}
