---
external help file: Nutanix.NcpCli.Cluster.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterRackableUnit.md
schema: 2.0.0
---

# Get-ClusterRackableUnit

## SYNOPSIS
Gets the Cluster Rackable Unit information from Nutanix Prism Central.

## SYNTAX

```
Get-ClusterRackableUnit [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String>
 [-ClusterExtID] <String> [[-RackableUnitExtID] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return the Cluster Rackable Unit information.

## EXAMPLES

### EXAMPLE 1
```
Get-ClusterRackableUnit -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew"
Gets the specific Ext ID Cluster Rackable Units information from the Prism Central Appliance.
```

### EXAMPLE 2
```
Get-ClusterRackableUnit -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -RackableUnitExtID "4321fe1w-312ed-aee514325-feqwf"
Gets the specific Ext ID Cluster Rackable Units Information for a specific Unit from the Prism Central Appliance.
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

### -RackableUnitExtID
(Optional) Specifies the Ext ID (UUID) of the Rackable you want to return

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function will take inputs via pipeline.
## OUTPUTS

### Returns the Nutanix Cluster Rackable Unit information based on the parameters passed into the function.
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterRackableUnit.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterRackableUnit.md)

