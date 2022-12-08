# Get-MdtOSGuid

Connect to MDT Server and gather Operating System GUID.

## Syntax

```PowerShell
Get-MdtOSGuid
    [-WinVerBuild] <String>
    [-OSversion] <String>
    [<CommonParameters>]
```

## Description

This function will connect to a MDT server and obtain a list of all the operating systems available using OperatingSystems.xml file. It will then search for the selected Operating System GUID and return this.

## Examples

### EXAMPLE 1:

```PowerShell
Get-MdtOSGuid -WinVerBuild "2210" -OSVersion "SRV"
```

Connects the MDT server and gathers all the OS versions available for the "SRV" search string and the specific version "2210" then adds the GUID as a return value

## Parameters

### -WinVerBuild

The Windows version to build (Server/Desktop).

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
