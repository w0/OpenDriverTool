function Find-DellDrivers {
    [CmdletBinding()]
    param (
        # Driver Packages, Typically comes from DriverPackCatalog.xml
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [psobject]
        $DriverPackCatalog,

        # Model e.g. 'Optiplex 7080' 
        [Parameter(Mandatory = $true)]
        [string]
        $Model,

        # OS version e.g. 'win10'
        [Parameter(Mandatory = $false)]
        [string[]]
        $OSVersion
    )
   
    process {
        $DriverPackCatalog.DriverPackManifest.DriverPackage | Where-Object { $_.SupportedSystems.Brand.Model.name -eq $Model -and $_.SupportedOperatingSystems.OperatingSystem.osCode -eq $OSVersion}
    }       
}