---
external help file: OpenDriverTool-help.xml
Module Name: OpenDriverTool
online version:
schema: 2.0.0
---

# Get-KnownModels

## SYNOPSIS
Get known models from the configuration manager site.

## SYNTAX

```
Get-KnownModels [-Make] <String> [-SiteCode] <String> [-SiteServerFQDN] <String>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The `Get-KnownModels` cmdlet will return an array models from the configuration manager site.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-KNownModels -Make Dell -SiteCode CAS -SiteServerFQDN 'abc.contoso.com'
```

Get all known Dell models from the specified configuration manager site.

## PARAMETERS

### -Make
Manufacturer of the computer.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: Dell, Microsoft

Required: True
Position: 0
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
Position: 1
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
Position: 2
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
