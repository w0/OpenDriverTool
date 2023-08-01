function Expand-Drivers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Dell', 'Microsoft')]
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

    $Actions = @{
        'Dell.exe' = {
            Start-Process -FilePath $Path -ArgumentList ('/s /e="{0}"' -f $ExtractDir) -PassThru -Wait
        }

        'Dell.cab' = {
            Expand-Cab -Path $Path -Destination $ExtractDir
        }

        'Microsoft.msi' = {
            Start-Process msiexec.exe -ArgumentList ('/a {0} /QN TARGETDIR="{1}"' -f $Path.FullName, $ExtractDir) -PassThru -Wait
        }
    }

    $result = & ($Actions["$Make$($Path.Extension)"] ?? { throw 'Attempted unhanled driver extraction: {0}' -f "$Make$($Path.Extension)" })

    if ($result.ExitCode -ne 0) {
        throw 'Driver extraction reported non-zero exit code. {0}' -f $result.ExitCode
    }

    $ExtractDir
}