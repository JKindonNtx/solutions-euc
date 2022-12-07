# Get-MdtOS

Connect to MDT Server and gather Operating Systems.

## Syntax

```PowerShell
Get-MdtOS
    [-SearchString] <String>
    [-OSversion] <String>
    [<CommonParameters>]
```

## Description

This function will connect to a MDT server and obtain a list of all the operating systems available using the directories in the OS folder of the MDT share.

## Examples

### EXAMPLE 1:

```PowerShell
Get-MdtOS -SearchString "SRV" -OSVersion "SRV"
```

Connects the MDT server and gathers all the OS versions available for the "SRV" search string

## Parameters

### -SearchString

The folder search string to match against.

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -OSversion

The operating system version to match against.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
