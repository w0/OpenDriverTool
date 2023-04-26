function Find-DellBIOS {
    [CmdletBinding()]
    param (
        # Model name to search for
        [Parameter(mandatory)]
        [string]
        $Model,

        [Parameter(Mandatory)]
        [psobject]
        $DriverPackCatalog,

        [Parameter(Mandatory)]
        [psobject]
        $CatalogPC
    )

    begin {

        # Get Models from Dell, contains systemID. 
        $Models = $DriverPackCatalog.GetElementsByTagName('Model')

        # BIOS files. Find by systemID.
        $SoftwareComponents = $CatalogPC.GetElementsByTagName('SoftwareComponent')        

    }

    process {

        $systemID = ($Models.Where({ $_.Name -eq $Model}, 'First')).systemID

        # BIOS that matches our systemID
        $BIOSInstallers = $SoftwareComponents.Where( 
                { $_.Name.Display.'#cdata-section' -match 'BIOS' -and $_.SupportedSystems.Brand.Model.systemID -eq $systemID }
            )

        if ($BIOSInstallers.Count -gt 1) {
            $BIOSInstallers = $BIOSInstallers | Sort-Object -Property dateTime | Select-Object -Last 1 
        }

        $BIOSInstallers
    }
}