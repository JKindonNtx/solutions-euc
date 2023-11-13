---
external help file: Nutanix.NcpCli.Cluster.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterFaultTolerance.md
schema: 2.0.0
---

# Get-ClusterFaultTolerance

## SYNOPSIS
Gets the Cluster Fault Tolerance level from Nutanix Prism Central.

## SYNTAX

```
Get-ClusterFaultTolerance [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String>
 [-ClusterExtID] <String> [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return the Cluster Fault Tolerance level for the passed in cluster.

## EXAMPLES

### EXAMPLE 1
```
Get-ClusterFaultTolerance -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "432re2de21-d1323d21-ewqER312QE3R-DFEQWFEDW"
Gets the Cluster with Ext ID "432re2de21-d1323d21-ewqER312QE3R-DFEQWFEDW" Fault Tolerance level from the Prism Central Appliance.
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

### Returns the Nutanix Cluster Fault Tollerance information based on the parameters passed into the function.
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterFaultTolerance.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterFaultTolerance.md)

[Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli]()

