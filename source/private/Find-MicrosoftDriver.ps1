function Find-MicrosoftDriver {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Model,

        [Parameter(Mandatory)]
        [string]
        $OSVersion
    )
    
    $Catalog = 'https://raw.githubusercontent.com/OSDeploy/OSD/master/Catalogs/MicrosoftDriverPackCatalog.json'

    $Content = Invoke-RestMethod -Uri $Catalog

    $Content | Where-Object { $_.Product -EQ $Model -and $_.OSVersion -match $OSVersion } 
}