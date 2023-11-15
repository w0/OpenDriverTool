function Get-KnownModels {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [ValidateSet('Dell', 'Microsoft')]
        [string]
        $Make,

        [Parameter(Mandatory)]
        [string]
        $SiteCode,

        [Parameter(Mandatory)]
        [string]
        $SiteServerFQDN
    )

    Connect-SCCM -SiteCode $SiteCode -SiteServerFQDN $SiteServerFQDN

    Push-Location ('{0}:' -f $SiteCode)

    switch ($Make) {
        'Dell' {
            $DellCompSys = "Select Distinct Manufacturer, Model from SMS_G_System_COMPUTER_SYSTEM Where Manufacturer = 'Dell Inc.' and (Model like 'Optiplex%' or Model like 'Latitude%' or Model like 'Precision%' or Model like 'XPS%')"
            $DellMSInfo = "Select Distinct SystemManufacturer, SystemProductName, SystemSKU from SMS_G_System_MS_SystemInformation Where BaseBoardManufacturer = 'Dell Inc.'"
            
            try {
                $Result = Invoke-CMWmiQuery -Query $DellMSInfo -Option FastExpectResults
                break
            } catch {
                Write-Warning -Message "Unable to query the MS_SystemInformation class. Is this class enabled in your hardware inventory?"
                Write-Warning -Message "Will query SMS_G_System_COMPUTER_SYSTEM instead."
            }

            $Result = Invoke-CMWmiQuery -Query $DellCompSys -Option FastExpectResults

        }
        'Microsoft' {
            $MicrosoftMSInfo = "Select Distinct SystemManufacturer, SystemProductName, SystemSKU from SMS_G_System_MS_SYSTEMINFORMATION Where SystemManufacturer like 'Microsoft%' and SystemProductName like 'Surface%'"

            try {
                $Result = Invoke-CMWmiQuery -Query $MicrosoftMSInfo -Option FastExpectResults
            } catch {
                Write-Error -Message "Unable to query the MS_SystemInformation class. Is this class enabled in your hardware inventory?"
            }
        }
    }

    Pop-Location

    Write-Output $Result
}