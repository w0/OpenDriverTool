function Get-RemoteFile {
    [CmdletBinding()]
    param (
        # Url to download 
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]
        $Url,
        
        # Destination 
        [Parameter(Mandatory = $true)]
        [io.directoryInfo]
        $Destination,

        # Checksum
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Hash')]
        [string]
        $Hash,

        # Algorithm
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Hash')]
        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]
        $Algorithm
    )
    
    process {

        $Filename = ([uri] $Url).Segments[-1]
        
        $OutFile = [System.IO.Path]::Combine($Destination, $Filename)

        Invoke-WebRequest -Uri $Url -OutFile $OutFile | Out-Null

        if ($Hash) {

            $FileHash = (Get-FileHash $OutFile -Algorithm $Algorithm).Hash

            if ($Hash -ne $FileHash) {
                throw 'Failed to verify hash'
            }
        }

        [io.fileinfo] $OutFile

    }
}