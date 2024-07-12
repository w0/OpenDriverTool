function Remove-Packages {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Dell', 'Microsoft')]
        [string]
        $Make,

        [Parameter(Mandatory)]
        [ValidateSet('Drivers', 'BIOS Update')]
        [string]
        $PackageType,

        [Parameter(Mandatory)]
        [string]
        $SiteCode,

        [Parameter(Mandatory)]
        [string]
        $SiteServerFQDN
    )

    $SearchString = '{0} - {1} *' -f $PackageType, $Make

    Write-Debug -Message $SearchString

    Connect-SCCM -SiteCode $SiteCode -SiteServerFQDN $SiteServerFQDN

    Push-Location ('{0}:' -f $SiteCode)

    $QueryResult = Get-CMPackage -Name $SearchString -Fast

    $CMPackages = $QueryResult | Group-Object Name | Where-Object Count -gt 1

    foreach ($Group in $CMPackages) {

        $PkgsToDelete = $Group.Group | Sort-Object -Property SourceDate | Select-Object -First ($Group.Count - 1)

        foreach ($Package in $PkgsToDelete) {
            if ($PSCmdlet.ShouldProcess("$($Package.Name) Version: $($Package.Version)", "Remove Package")) {

                Remove-CMPackage -InputObject $Package -Force

                Pop-Location

                if (Test-Path $Package.PkgSourcePath) {
                   Remove-Item -Path $Package.PkgSourcePath -Recurse -Force
                }

                Push-Location ('{0}:' -f $SiteCode)
            }
        }
    }

    Pop-Location
}