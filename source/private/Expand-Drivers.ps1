function Expand-Drivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Dell')]
        [string]
        $Make,

        [Parameter(Mandatory)]
        [object]
        $Path,

        [Parameter(Mandatory)]
        [object]
        $DestinationPath 
    )
    
    $ExtractDir = Join-Path $DestinationPath (New-Guid).Guid

    New-Item $ExtractDir -ItemType Directory -ErrorAction Stop | Out-Null

    switch ($Path.Extension) {
        '.exe' {
            Start-Process -FilePath $Path -ArgumentList ('/s /e="{0}"' -f $ExtractDir) -Wait; break
        }
        '.cab' {
            Expand-Cab -Path $Path -Destination $ExtractDir; break
        }
        default { throw 'unhandled file extension {0}. unable to extract drivers.' -f $_ }
    }

    $ExtractDir
}