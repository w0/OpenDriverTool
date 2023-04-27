function Expand-Cab {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [io.fileinfo]
        $Path,

        # Parameter help description
        [Parameter()]
        [io.directoryinfo]
        $DestinationPath,

        # Filename
        [Parameter()]
        [string]
        $FileName
    )

    process {
        $Proc = @{
            FilePath     = 'expand.exe'
            Wait         = $true
            ArgumentList = @(
                '-R',
                '-F:*',
                "$($Path.FullName)",
                "$($DestinationPath.FullName)"
            )
        }

        Start-Process @Proc | Out-Null

    }
}