---
external help file: Nutanix.NcpCli.Cluster.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-HostNIC.md
schema: 2.0.0
---

# Get-HostNIC

## SYNOPSIS
Gets the Host NICS from Nutanix Prism Central.

## SYNTAX

```
Get-HostNIC [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String> [-ClusterExtID] <String>
 [-HostExtID] <String> [[-HostNICExtID] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return all the Host NICS currently registered.

## EXAMPLES

### EXAMPLE 1
```
Get-HostNIC -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543"
Gets the Host NICs from the specific Cluster passed in from the Prism Central Appliance.
```

### EXAMPLE 2
```
Get-HostNIC -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543" -HostNICExtID "34225234-431321414-341324-3414"
Gets the Specific Host NIC from the specific Cluster passed in from the Prism Central Appliance.
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

### -HostExtID
Specifies the Ext ID (UUID) of the Host you want to return.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HostNICExtID
Specifies the Ext ID (UUID) of the Host NIC you want to return.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function will take inputs via pipeline.
## OUTPUTS

### Returns the Nutanix Host NIC information based on either the Host passed in or the individual NIC.
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-HostNIC.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-HostNIC.md)

