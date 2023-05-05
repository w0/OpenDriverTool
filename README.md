# Open Driver Tool

A powershell module to help download drivers.

# Usage

```powershell
$Splat = @{
    Make               = 'Dell'
    Model              = 'Latitude 5420'
    ContentShare       = '\\configmgrnetworkshare\Drivers'
    SiteCode           = 'ABC'
    SiteServerFQDN     = 'abc.contoso.com'
    DistributionPoints = ( 'abc.contoso.com', 'abc2.contoso.com')
} 

Update-Model @Splat -OSVersion 'Windows 11'
```