function Confirm-ExistingPackage {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [hashtable]
        $Package,


        [Parameter(Mandatory)]
        [string]
        $SiteCode
    )
    
    Push-Location ('{0}:' -f $SiteCode)

    Get-CMPackage -Name $Package.Name -Fast | Where-Object Version -EQ $Package.Version
    
    Pop-Location
}