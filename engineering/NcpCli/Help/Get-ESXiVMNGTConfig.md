---
external help file: Nutanix.NcpCli.VMM.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ESXiVMNGTConfig.md
schema: 2.0.0
---

# Get-ESXiVMNGTConfig

## SYNOPSIS
Gets the ESXi VM NGT Config from Nutanix Prism Central.

## SYNTAX

```
Get-ESXiVMNGTConfig [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String> [-VMExtID] <String>
 [[-VerbosePreference] <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return the ESXi VM NGT Config.

## EXAMPLES

### EXAMPLE 1
```
Get-ESXiVMNGTConfig -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -VMExtID "08a4c861-3c9a-43b4-a8e0-fdb065dcfe4b"
Gets the ESXi VM with Ext ID 08a4c861-3c9a-43b4-a8e0-fdb065dcfe4b NGT Config from the Prism Central Appliance.
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

### -VMExtID
Specifies VM Ext ID

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

### -VerbosePreference
{{ Fill VerbosePreference Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: $PSCmdlet.GetVariableValue('VerbosePreference')
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function will take inputs via pipeline as string
## OUTPUTS

### Returns an object with the query result and either the data from the query or the error message
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ESXiVMNGTConfig.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ESXiVMNGTConfig.md)
