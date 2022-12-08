# Update-MDTTaskSequence

Updates the MDT Control File.

## Syntax

```PowerShell
Update-MDTTaskSequence
    [-TaskSequenceID] <String>
    [-GUID] <String>
    [<CommonParameters>]
```

## Description

This function will update the MDT Task Sequence with the new OS to install.

## Examples

### EXAMPLE 1:

```PowerShell
Update-MdtTaskSequence -TaskSequenceID "WSRV-BASE" -Guid "{1-2-3-4-5-6-7-8}"
```

Updates the MDT Task Sequence "WSRV-BASE" to use a new OS.

## Parameters

### -TaskSequenceID

The Task Sequence ID to Update.

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -GUID

The Operating System GUID

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

