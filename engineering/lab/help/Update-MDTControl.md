# Update-MDTControl

Updates the MDT Control File.

## Syntax

```PowerShell
Update-MDTControl
    [-TaskSequenceID] <String>
    [-VMMAC] <String>
    [-Name] <String>
    [<CommonParameters>]
```

## Description

This function will update the MDT control file to allow for auto start of a Task Sequence.

## Examples

### EXAMPLE 1:

```PowerShell
Update-MDTControl -Name "VM" -TaskSequenceID "WSRV-BASE" -VMMAC "12:23:34:45:56:67"
```

Updates the MDT Control file for the machine "VM" to run Task Sequence "WSRV-BASE".

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

### -VMMAC

The VM MAC address.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -Name

The VM name.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
