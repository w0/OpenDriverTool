---
external help file: OpenDriverTool-help.xml
Module Name: OpenDriverTool
online version:
schema: 2.0.0
---

# Update-Model

## SYNOPSIS
Controller script to assist with automating the usage of the manufactuer specific update cmdlets.

## SYNTAX

### PointAndGroup
```
Update-Model -Make <String> -Model <String> -OSVersion <String> [-DownloadType <String>]
 [-WorkingDir <DirectoryInfo>] -ContentShare <DirectoryInfo> -SiteCode <String> -SiteServerFQDN <String>
 -DistributionPoints <String[]> -DistributionPointGroups <String[]> [<CommonParameters>]
```

### DistributionPoints
```
Update-Model -Make <String> -Model <String> -OSVersion <String> [-DownloadType <String>]
 [-WorkingDir <DirectoryInfo>] -ContentShare <DirectoryInfo> -SiteCode <String> -SiteServerFQDN <String>
 -DistributionPoints <String[]> [<CommonParameters>]
```

### DistributionPointGroups
```
Update-Model -Make <String> -Model <String> -OSVersion <String> [-DownloadType <String>]
 [-WorkingDir <DirectoryInfo>] -ContentShare <DirectoryInfo> -SiteCode <String> -SiteServerFQDN <String>
 -DistributionPointGroups <String[]> [<CommonParameters>]
```

## DESCRIPTION
The `Update-Model` cmdlet finds either the latest driver or bios update for the specified computer make and model. If the latest version is not already in configmgr. It downloads the content locally, copies it to the specified content share and finally creates a standard package in configmgr.

`Update-Model` doesn't return any usable output. It will only write a log of the actions it is taking to the host.

## EXAMPLES

### Example 1
```powershell
PS C:\> Update-Model -Make 'Dell' -Model 'Optiplex 7090' -OSVersion 'Windows 11' -ContentShare '\\contoso\configmgr\drivers' -SiteCode 'CAS' -SiteServerFQDN 'abc.contoso.com' -DistributionPoints 'abc.contoso.com', 'abc2.contoso.com'
```

Downloads both the latest driver and bios update supporting windows 11 for the Dell Optiplex 7090. A standard package on the specified site will be created for both the drivers and bios.

## PARAMETERS

### -ContentShare
Specifies the path of the content. The site system server requires permission to read the content files.

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DistributionPointGroups
Specify an array of distribution point groups to which to distribute the content.

```yaml
Type: String[]
Parameter Sets: PointAndGroup, DistributionPointGroups
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DistributionPoints
Specify an array of distribution points to which to distribute the content.

```yaml
Type: String[]
Parameter Sets: PointAndGroup, DistributionPoints
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DownloadType
Choose which type of content you'd like to download.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Driver, Bios, Both

Required: False
Position: Named
Default value: Both
Accept pipeline input: False
Accept wildcard characters: False
```

### -Make
Manufacturer of the computer.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Dell

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Model
Model of the computer to download drivers or bios updates for.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSVersion
Targeted OS version for the requested driver package or bios updates.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Windows 10, Windows 11

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteCode
Specify the sitecode of the confimgr site to connect to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteServerFQDN
Specify the site server fqdn to connect to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkingDir
A local or network location used when downloading content.

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Object
## NOTES

## RELATED LINKS
