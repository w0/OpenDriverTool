function New-Log {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $Message
    )
    
    $Message | ForEach-Object {
        if (-not $NoHostOutput) { Write-Host $_ }
    }
}

Set-Alias Log New-Log