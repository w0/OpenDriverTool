function Get-DellCatalog {
    [CmdletBinding()]
    param (
        # Parameter help description
        [Parameter()]
        [string]
        $URL = 'https://downloads.dell.com/catalog/'
    )

    process {

        $Request = Invoke-WebRequest -Uri $URL -UseBasicParsing

        # Using the operator due to powershell 5s split method behavior
        ($Request.Content -split '<br>').foreach({
            if ($PSItem -match '^\s*(?<date>\d.+?[A|P]M)\s+(?<size>\d+)\s+?<A HREF=".+?">(?<filename>.+)<\/A>$') {
                [PSCustomObject]@{
                    Filename = $Matches['filename']
                    Date     = [datetime] $Matches['date']
                    Size     = [int] $Matches['size']
                    URL      = $URL + $Matches['filename']
                }
            }
        })
    }
}