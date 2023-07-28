function Clean-Temp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [io.directoryInfo]
        $Path
    )
    
    Get-ChildItem -Path $Path | Remove-Item -Recurse -Force
}