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

    function extract {
        param (
            $DriverFile
        )

        $ExtractDir = Join-Path $WorkingDir (New-Guid).Guid

        New-Item $ExtractDir -ItemType Directory -ErrorAction Stop | Out-Null

        switch ($DriverFile.Extension) {
            '.exe' {
                Start-Process -FilePath $DriverFile -ArgumentList ('/s /e="{0}"' -f $ExtractDir) -Wait; break
            }
            '.cab' {
                Expand-Cab -Path $DriverFile -Destination $ExtractDir; break
            }
            default { throw 'unhandled file extension {0}. unable to extract drivers.' -f $_ }
        }

        $ExtractDir

    }

    function compress {
        param (
            $Content
        )

        $Child = Get-ChildItem $Content

        Compress-Archive -Path $Child -DestinationPath $Content\DriverPackage.zip -PassThru

    }

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

    $ExtractedContent = extract $DriverFile

    $Archive = compress $ExtractedContent

    $RemoteDir = Join-Path $ContentShare $DriverFile.BaseName

    New-Item $RemoteDir -ItemType Directory -ErrorAction Stop | Out-Null

    Copy-Item -Path $Archive -Destination $RemoteDir

}
