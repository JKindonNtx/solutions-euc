---
external help file: Nutanix.NcpCli.Cluster.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-Host.md
schema: 2.0.0
---

# Get-Host

## SYNOPSIS
Gets the Hosts from Nutanix Prism Central.

## SYNTAX

```
Get-Host [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String> [[-ClusterExtID] <String>]
 [[-HostExtID] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return all the Hosts currently registered.

## EXAMPLES

### EXAMPLE 1
```
Get-Host -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
Gets the current Hosts from the Prism Central Appliance.
```

### EXAMPLE 2
```
Get-Host -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew"
Gets all the Hosts from the specific Cluster passed in from the Prism Central Appliance.
```

### EXAMPLE 3
```
Get-Host -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543"
Gets the Host from the specific Cluster passed in from the Prism Central Appliance.
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
(Optional) Specifies the Ext ID (UUID) of the Cluster Hosts you want to return.

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

### -HostExtID
(Optional) Specifies the Ext ID (UUID) of the Host you want to return.

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
### None
## OUTPUTS

### Returns the Nutanix Host information based on either Prism Central, the Cluster or the Host passed in.
### System.Management.Automation.Host.PSHost
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-Host.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-Host.md)

[https://go.microsoft.com/fwlink/?LinkID=2097110](https://go.microsoft.com/fwlink/?LinkID=2097110)

