function Update-Model {
    [CmdletBinding()]
    param (

        [Parameter()]
        [string]
        $Make,

        [Parameter()]
        [string]
        $Model,

        [Parameter()]
        [string]
        $OSVersion,

        [Parameter()]
        [io.directoryInfo]
        $WorkingDir,

        [Parameter()]
        [io.directoryInfo]
        $ContentShare

    )


    if (-not $WorkingDir) {
        $WorkingDir = ([System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "OpenDriverTool"))
    }

    New-Item $WorkingDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

    New-Item $WorkingDir\Content -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    
    $DellCatalog = Get-DellCatalog

    $DriverPackCatalogUrl = $DellCatalog.Where( {$_.Filename -eq 'DriverPackCatalog.CAB'}, 'First' )
    $CatalogPCUrl      = $DellCatalog.Where( { $_.Filename -eq 'CatalogPC.cab'}, 'First' )
    
    $DriverPackCatalogCAB = $DriverPackCatalogUrl.Url | Get-RemoteFile -Destination $WorkingDir

    $CatalogPCCAB = $CatalogPCUrl.Url | Get-RemoteFile -Destination $WorkingDir

    Expand-Cab -Path $DriverPackCatalogCAB -Destination $WorkingDir\Content
    Expand-Cab -Path $CatalogPCCAB -Destination $WorkingDir\Content

    [xml] $DriverPackCatalog = Get-Content -Path "$WorkingDir\Content\DriverPackCatalog.xml"
    [xml] $CatalogPC = Get-Content -Path "$WorkingDir\Content\CatalogPC.xml"

    $Driver = Find-DellDrivers -DriverPackCatalog $DriverPackCatalog -Model $Model -OSVersion $OSVersion

    $BIOS = Find-DellBIOS -Model $Model -DriverPackCatalog $DriverPackCatalog -CatalogPC $CatalogPC

    $BIOSFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $BIOS.path) -Destination $WorkingDir -Hash $BIOS.hashMD5 -Algorithm MD5
    $DriverFile = Get-RemoteFile -Url ('{0}/{1}' -f 'https://downloads.dell.com', $Driver.path) -Destination $WorkingDir -Hash $Drivers.hashMD5 -Algorithm MD5

}
