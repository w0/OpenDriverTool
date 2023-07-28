function Start-ContentDistribution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $CMPackage,

        [Parameter(Mandatory)]
        [string]
        $SiteCode,
        
        [Parameter(Mandatory, ParameterSetName = 'DistributionPoints')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DistributionPoints,

        [Parameter(Mandatory, ParameterSetName = 'DistributionPointGroups')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DistributionPointGroups
    )
    
    begin {
        Push-Location ('{0}:' -f $SiteCode)
    }
    
    process {
        switch ($PSBoundParameters.Keys) {
            'DistributionPoints'      { Start-CMContentDistribution -InputObject $CMPackage -DistributionPointName $DistributionPoints }
            'DistributionPointGroups' { Start-CMContentDistribution -InputObject $CMPackage -DistributionPointGroupName $DistributionPointGroups }
        }
    }
    
    end {
        Pop-Location
    }
}