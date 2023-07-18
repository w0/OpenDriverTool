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
        [ValidateSet('Driver', 'Bios', 'Both')]
        [string]
        $DownloadType = 'Both',

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

    $Driver = @{
        Model = $Model
        OSVersion = $OSVersion
        WorkingDir = $WorkingDir
        ContentShare = $ContentShare
        SiteCode = $SiteCode
        SiteServerFQDN = $SiteServerFQDN
        DistributionPoints = $DistributionPoints
    }

    $Bios = @{
        Model = $Model
        WorkingDir = $WorkingDir
        ContentShare = $ContentShare
        SiteCode = $SiteCode
        SiteServerFQDN = $SiteServerFQDN
        DistributionPoints = $DistributionPoints
    }

    switch ($Make) {
        'Dell' {
            if ($DownloadType -eq 'Driver' -or $DownloadType -eq 'Both') {
                Update-DellDriver @Driver
            }

            if ($DownloadType -eq 'Bios' -or $DownloadType -eq 'Both') {
                Update-DellBios @Bios
            }
        }
    }

    Clean-Temp -Path $WorkingDir
}
