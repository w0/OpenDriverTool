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

    "Updating drivers for Dell $Model" | Log

    Path-Creator -Parent $WorkingDir -Child 'Content' | Out-Null

    $DriverPackCatalogUrl = 'https://downloads.dell.com/catalog/DriverPackCatalog.CAB'

    '  Getting Dell cabinet files...' | Log
    '    Downloading: {0}' -f $DriverPackCatalogUrl | Log
    $DriverPackCatalogCAB = $DriverPackCatalogUrl | Get-RemoteFile -Destination $WorkingDir

    Expand-Cab -Path $DriverPackCatalogCAB -Destination $WorkingDir\Content

    [xml] $DriverPackCatalog = Get-Content -Path "$WorkingDir\Content\DriverPackCatalog.xml"

    $Driver = Find-DellDrivers -DriverPackCatalog $DriverPackCatalog -Model $Model -OSVersion ($OSVersion -replace '\s', '')

    if (-not $Driver) {
        Write-Error "Failed to find a driver. Verify that the name of the model is correct and a pack is published for $OSVersion" -ErrorAction Stop
    } 

    '  Found Driver: {0}' -f $Driver.path | Log

    $DriverPackage = @{
        Name = 'Drivers - {0} {1} - {2} {3}' -f 'Dell', $Model, $OSVersion, $Driver.SupportedOperatingSystems.OperatingSystem.osArch
        Version = $Driver.dellVersion
        Manufacturer = 'Dell'
        Description = '(Models included:{0})' -f ($Driver.SupportedSystems.brand.model.systemID -join ';')
    }

    if ($PSCmdlet.ParameterSetName -ne 'DownloadOnly') {
        Connect-SCCM -SiteCode $SiteCode -SiteServerFQDN $SiteServerFQDN
        $ExistingPackage = Confirm-ExistingPackage -Package $DriverPackage -SiteCode $SiteCode
    }

    if ($ExistingPackage) {
        '  Latest driver already in configmgr.' | Log
        return
    }

    if ($PSCmdlet.ParameterSetName -ne 'DownloadOnly') {
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
        $CMPackage = New-Package -Package $DriverPackage -Type 'Driver' -SiteCode $SiteCode -ContentPath $DriverContent -Make 'Dell'

        switch ($PSBoundParameters.Keys) {
            'DistributionPoints'      { Start-ContentDistribution -CMPackage $CMPackage -SiteCode $SiteCode -DistributionPoints $DistributionPoints }
            'DistributionPointGroups' { Start-ContentDistribution -CMPackage $CMPackage -SiteCode $SiteCode -DistributionPointGroups $DistributionPointGroups }
        }

    }

    if ($PSCmdlet.ParameterSetName -eq 'DownloadOnly') {
        if (-not (Test-Path $ContentShare)) {
            New-Item -Path $ContentShare -ItemType Directory | Out-Null
        }

        '    Downloading: {0}' -f $Driver.path  | Log
        $DriverFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $Driver.path) -Destination $ContentShare -Hash $Drivers.hashMD5 -Algorithm MD5

        '  Downloaded: {0}' -f $DriverFile.FullName | Log
    }

}
