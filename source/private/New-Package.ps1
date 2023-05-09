function New-Package {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $Package,

        [Parameter(Mandatory)]
        [ValidateSet('Driver', 'BIOS')]
        [string]
        $Type,

        [Parameter(Mandatory)]
        [io.directoryInfo]
        $ContentPath,

        [Parameter(Mandatory)]
        [string]
        $Make,

        [Parameter(Mandatory)]
        [string]
        $SiteCode,
        
        [Parameter(Mandatory)]
        [string[]]
        $DistributionPoints
    )
    
    begin {
        Push-Location ('{0}:' -f $SiteCode)
    }
    
    process {
        $CMPackage = New-CMPackage @Package -Path $ContentPath
        $CMPackage | Move-CMObject -FolderPath ('{0}:\Package\{1} Packages\{2}' -f $SiteCode, $Type, $Make)
        Set-CMPackage -InputObject $CMPackage -EnableBinaryDeltaReplication $true

        Start-CMContentDistribution -InputObject $CMPackage -DistributionPointName $DistributionPoints
    }
    
    end {
        Pop-Location
    }
}