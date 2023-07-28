function Path-Creator {
    [CmdletBinding()]
    param (
    
        [Parameter(Mandatory)]
        [io.directoryInfo]
        $Parent,

        [Parameter(Mandatory)]
        [string[]]
        $Child
    )

    $Path = Join-Path $Parent ($Child -join '\')

    if (-not (Test-Path $Path)) {
        New-Item $Path -ItemType Directory -ErrorAction SilentlyContinue
        return
    }

    [io.directoryinfo] $Path
}