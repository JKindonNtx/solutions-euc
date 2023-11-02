---
external help file: Nutanix.NcpCli.Core.psm1-help.xml
Module Name: Nutanix.NcpCli
online version:
schema: 2.0.0
---

# Get-ReturnData

## SYNOPSIS
Checks for a $null or blank variable.

## SYNTAX

```
Get-ReturnData [[-Result] <Object>] [[-CmdLet] <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function will check a variable for either a $null value or an empty string.

## EXAMPLES

### EXAMPLE 1
```
Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name
Gets the return data based on the information in $Result.
```

## PARAMETERS

### -Result
Specifies the Result Data to return.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CmdLet
Specifies the function name that called this Return Data.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### Returns either the data or a warning error depending on whats passed into the function.
## NOTES

## RELATED LINKS

[Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ReturnData.md]()

[Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli]()

