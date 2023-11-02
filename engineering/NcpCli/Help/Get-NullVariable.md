---
external help file: Nutanix.NcpCli.Core.psm1-help.xml
Module Name: Nutanix.NcpCli
online version:
schema: 2.0.0
---

# Get-NullVariable

## SYNOPSIS
Checks for a $null or blank variable.

## SYNTAX

```
Get-NullVariable [[-Check] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function will check a variable for either a $null value or an empty string.

## EXAMPLES

### EXAMPLE 1
```
Get-NullVariable -Check $VariableName
Checks the $VariableName variable for a $null or blank value.
```

## PARAMETERS

### -Check
Specifies the variable to check.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### Returns an $true or $false based on the contents of the $Check variable.
## NOTES

## RELATED LINKS

[Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-NullVariable.md]()

[Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli]()

