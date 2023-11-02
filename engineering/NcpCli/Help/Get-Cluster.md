---
external help file: Nutanix.NcpCli.Cluster.psm1-help.xml
Module Name: Nutanix.NcpCli
online version:
schema: 2.0.0
---

# Get-Cluster

## SYNOPSIS
Returns the registered Clusters from Nutanix Prism Central.

## SYNTAX

```
Get-Cluster [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String> [[-ClusterExtID] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return all the Clusters currently registered.

## EXAMPLES

### EXAMPLE 1
```
Get-Cluster -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
Gets the current Clusters from the Prism Central Appliance.
```

### EXAMPLE 2
```
Get-Cluster -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew"
Gets the specific Ext ID Cluster from the Prism Central Appliance.
```

### EXAMPLE 3
```
Get-Cluster -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -Verbose
Gets the specific Ext ID Cluster from the Prism Central Appliance with Verbose output.
```

## PARAMETERS

### -PrismIP
Specifies the Prism Central IP.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PrismUserName
Specifies the Prism Central User Name.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PrismPassword
Specifies the Prism Central Password.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ClusterExtID
(Optional) Specifies the Ext ID (UUID) of the Cluster you want to return.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function will take inputs via pipeline.
## OUTPUTS

### Returns the Nutanix Cluster information based on the parameters passed into the function.
## NOTES

## RELATED LINKS

[Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-Cluster.md]()

[Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli]()

