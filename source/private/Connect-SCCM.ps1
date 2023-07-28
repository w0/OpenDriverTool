function Connect-SCCM {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $SiteCode,

        [Parameter(Mandatory)]
        [string]
        $SiteServerFQDN
    )
    
    try {
        Import-Module (Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH -Parent) 'ConfigurationManager.psd1')
    } catch {
        throw 'The specified module ''ConfigurationManager'' was not loaded because no valid module file was found. Is the admin console installed?'
    }

    if (-not (Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name $SiteCode -PSProvider "CMSite" -Root $SiteServerFQDN -Description "SCCM Site" | Out-Null
    }
}