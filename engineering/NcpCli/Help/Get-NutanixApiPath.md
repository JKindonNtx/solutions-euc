---
external help file: Nutanix.NcpCli.Core.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-NutanixApiPath.md
schema: 2.0.0
---

# Get-NutanixApiPath

## SYNOPSIS
Builds the Nutanix Api Path.

## SYNTAX

```
Get-NutanixApiPath [-NameSpace] <String> [[-VerbosePreference] <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function will take in a value and build the Nutanix Api Path based on the version of the Api being used.

## EXAMPLES

### EXAMPLE 1
```
Get-NutanixApiPath -NameSpace "Tasks" 
Builds the ApiPath for the NameSpace Tasks.
```

## PARAMETERS

### -NameSpace
Specifies the Api NameSpace

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

### -VerbosePreference
{{ Fill VerbosePreference Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $PSCmdlet.GetVariableValue('VerbosePreference')
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### This function will take inputs via pipeline as string
## OUTPUTS

### Returns an object with the relevant Api Path
## NOTES

## RELATED LINKS

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-NutanixApiPath.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-NutanixApiPath.md)

