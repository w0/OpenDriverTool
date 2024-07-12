function Update-MicrosoftDriver {
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

    "Updating drivers for Microsoft $Model" | Log

    '  Checking catalog for available driver.' | Log
    
    $Driver = Find-MicrosoftDriver -Model $Model -OSVersion $OSVersion

    if (-not $Driver) {
        Write-Error -Message 'Unable to find a driver for the specified model. Please reference https://raw.githubusercontent.com/OSDeploy/OSD/master/Catalogs/MicrosoftDriverPackCatalog.json for "Product" models.' -ErrorAction Stop
    } 

    '  Found Driver: {0}' -f $Driver.FileName | Log

    $DriverPackage = @{
        Name = 'Drivers - {0} {1} - {2}' -f 'Microsoft', $Model, $Driver.OSVersion
        Version = ($Driver.FileName -split '_' | Select-Object -last 1).trim('.msi')
        Manufacturer = 'Microsoft'
        Description = '(Models included:{0})' -f $Driver.Product
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
        
        '    Downloading: {0}' -f $Driver.FileName  | Log
        $DriverFile = Get-RemoteFile -Url $Driver.Url -Destination $WorkingDir

        '    Extracting: {0}' -f $DriverFile.FullName | Log
        $ExtractedContent = Expand-Drivers -Make 'Microsoft' -Path $DriverFile -Destination $WorkingDir

        '    Compressing driver package.'
        $Archive = Compress-Drivers -ContentPath $ExtractedContent

        $DriverPath = (
            'Microsoft',
            $Model,
            'Driver',
            $OSVersion,
            $DriverPackage.Version
        )

        $DriverContent = Path-Creator -Parent $ContentShare -Child $DriverPath

        Copy-Item -Path $Archive -Destination $DriverContent


        '    Creating driver package in sccm.'
        $CMPackage = New-Package -Package $DriverPackage -Type 'Driver' -SiteCode $SiteCode -ContentPath $DriverContent -Make 'Microsoft'

        switch ($PSBoundParameters.Keys) {
            'DistributionPoints'      { Start-ContentDistribution -CMPackage $CMPackage -SiteCode $SiteCode -DistributionPoints $DistributionPoints }
            'DistributionPointGroups' { Start-ContentDistribution -CMPackage $CMPackage -SiteCode $SiteCode -DistributionPointGroups $DistributionPointGroups }
        }

    } 

    if ($PSCmdlet.ParameterSetName -eq 'DownloadOnly') {
        if (-not (Test-Path $ContentShare)) {
            New-Item -Path $ContentShare -ItemType Directory | Out-Null
        }

        '    Downloading: {0}' -f $Driver.FileName  | Log
        $DriverFile = Get-RemoteFile -Url $Driver.Url -Destination $ContentShare

        '  Downloaded: {0}' -f $DriverFile.FullName | Log
    }

}