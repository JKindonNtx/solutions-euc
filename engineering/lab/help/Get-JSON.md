# Get-JSON

Reads values from JSON File.

## Syntax

```PowerShell
Get-JSON
    [-JSONFile] <String>
    [<CommonParameters>]
```

## Description

This function will take in a JSON file and read the contents into a variable.

## Examples

### EXAMPLE 1:

```PowerShell
Get-JSON -JSONFile "CreateVM.json"
```

Gets the contents of the JSON file CreateVM.json

## Parameters

### -JSONFile

The JSON File to read.

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
