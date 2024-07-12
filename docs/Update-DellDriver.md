---
external help file: OpenDriverTool-help.xml
Module Name: OpenDriverTool
online version:
schema: 2.0.0
---

# Update-DellDriver

## SYNOPSIS
Downloads the latest driver package for the specified operating system version and creates a standard package in configmgr.

## SYNTAX

### PointAndGroup
```
Update-DellDriver -Model <String> -OSVersion <String> [-WorkingDir <DirectoryInfo>]
 -ContentShare <DirectoryInfo> -SiteCode <String> -SiteServerFQDN <String> -DistributionPoints <String[]>
 -DistributionPointGroups <String[]> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DistributionPoints
```
Update-DellDriver -Model <String> -OSVersion <String> [-WorkingDir <DirectoryInfo>]
 -ContentShare <DirectoryInfo> -SiteCode <String> -SiteServerFQDN <String> -DistributionPoints <String[]>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DistributionPointGroups
```
Update-DellDriver -Model <String> -OSVersion <String> [-WorkingDir <DirectoryInfo>]
 -ContentShare <DirectoryInfo> -SiteCode <String> -SiteServerFQDN <String> -DistributionPointGroups <String[]>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DownloadOnly
```
Update-DellDriver -Model <String> -OSVersion <String> [-WorkingDir <DirectoryInfo>]
 -ContentShare <DirectoryInfo> [-DownloadOnly] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The `Update-DellDriver` cmdlet finds the latest driver package from the Dell catalog for the specified model. If the latest version is not already in configmgr. It downloads the content locally, copies it to the specified content share and finally creates a standard package in configmgr.

`Update-DellDriver` doesn't return any usable output. It will only write a log of the actions it is taking to the host.

## EXAMPLES

### Example 1
```powershell
PS C:\> Update-DellDriver -Model 'Optiplex 7090' -OSVersion 'Windows 11' -ContentShare '\\contoso\configmgr\drivers' -SiteCode 'CAS' -SiteServerFQDN 'abc.contoso.com' -DistributionPoints 'abc.contoso.com', 'abc2.contoso.com'
```

Downloads the latest windows 11 drivers for the Dell Optiplex 7090, creates a standard package on the specified site and distributes the content. 

## PARAMETERS

### -ContentShare
Specifies the path of the content. The site system server requires permission to read the content files.

```yaml
Type: DirectoryInfo
Parameter Sets: (All)
Aliases: Destination

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

### -Model
Model of the Dell computer to download drivers for.

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
Targeted OS version for the requested driver package.

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
Parameter Sets: PointAndGroup, DistributionPoints, DistributionPointGroups
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
Parameter Sets: PointAndGroup, DistributionPoints, DistributionPointGroups
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

### -DownloadOnly
Only downloads the driver package to the specified ContentShare. Does not create a package in configmgr. 

```yaml
Type: SwitchParameter
Parameter Sets: DownloadOnly
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

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
