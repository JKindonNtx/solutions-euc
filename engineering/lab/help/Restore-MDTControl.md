# Restore-MDTControl

Restores the MDT Control File.

## Syntax

```PowerShell
Restore-MDTControl
    [-ControlFile] <String>
    [<CommonParameters>]
```

## Description

This function will restore the MDT control file back to the original.

## Examples

### EXAMPLE 1:

```PowerShell
Restore-MDTControl -ControlFile $MDTControlOriginal
```

Backs up the MDT control file and will return the object.

## Parameters

### -ControlFile

The variable holding the backed up control file.

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |