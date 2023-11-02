---
external help file: Nutanix.NcpCli.Core.psm1-help.xml
Module Name: Nutanix.NcpCli
online version: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Get-NutanixApiError.md
schema: 2.0.0
---

# Get-NutanixApiError

## SYNOPSIS
Decodes a Nutanix Api call error.

## SYNTAX

```
Get-NutanixApiError [-ErrorMessage] <Object> [<CommonParameters>]
```

## DESCRIPTION
This function will take in an Error message and Decode an Api call error.

## EXAMPLES

### EXAMPLE 1
```
Get-NutanixApiError -Error $Error 
Decodes the Api Error call for $Error.
```

## PARAMETERS

### -ErrorMessage
Specifies the Error Message to decode

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

[https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Get-NutanixApiError.md](https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Get-NutanixApiError.md)

