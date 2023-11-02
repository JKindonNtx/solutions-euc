---
external help file: Nutanix.NcpCli.Cluster.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterSNMP.md
schema: 2.0.0
---

# Get-ClusterSNMP

## SYNOPSIS
Gets the Cluster SNMP information from Nutanix Prism Central.

## SYNTAX

```
Get-ClusterSNMP [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String>
 [-ClusterExtID] <String> [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return the Cluster SNMP information.

## EXAMPLES

### EXAMPLE 1
```
Get-ClusterSNMP -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew"
Gets the specific Ext ID Cluster SNMP Information from the Prism Central Appliance.
```

## PARAMETERS

### -PrismIP
Specifies the Prism Central IP

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
Specifies the Prism Central User Name

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
Specifies the Prism Central Password

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
Specifies the Ext ID (UUID) of the Cluster you want to return.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
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

### Returns the Nutanix Cluster SNMP information based on the parameters passed into the function.
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterSNMP.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterSNMP.md)

