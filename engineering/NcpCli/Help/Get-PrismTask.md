---
external help file: Nutanix.NcpCli.Prism.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-PrismTask.md
schema: 2.0.0
---

# Get-PrismTask

## SYNOPSIS
Gets the Tasks from Nutanix Prism Central.

## SYNTAX

```
Get-PrismTask [-PrismIP] <String> [-PrismUserName] <String> [-PrismPassword] <String> [[-UUID] <String>]
 [[-VerbosePreference] <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function will run an Api call against Prism Central and will return all the Tasks.

## EXAMPLES

### EXAMPLE 1
```
Get-PrismTask -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
Gets the current Tasks from the Prism Central Appliance.
```

### EXAMPLE 2
```
Get-PrismTask -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -UUID "78a1e6e7-5900-4f2a-839e-3b993e364889"
Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Task from the Prism Central Appliance.
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

### -UUID
(Optional) Specifies the UUID of the Task you wish to return

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

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-PrismTask.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-PrismTask.md)

