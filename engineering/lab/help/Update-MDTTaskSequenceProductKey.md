# Update-MdtTaskSequenceProductKey

Update the MDT Task Sequence Product Key in the Unattend File.

## Syntax

```PowerShell
Update-MdtTaskSequenceProductKey
    [-JSON] <Object>
    [-TaskSequenceID] <String>
    [-SearchString] <String>
    [-WinVerBuild] <String>
    [<CommonParameters>]
```

## Description

This function will update the MDT Task Sequence Product Key in the Unattend File for Server Builds as this is a required step to have a zero touch install.

## Examples

### EXAMPLE 1:

```PowerShell
Update-MdtTaskSequenceProductKey -JSON $JSON -TaskSequenceID "WSRV-BASE" -SearchString "SRV" -WinVerBuild "SRV"
```

Updates the MDT Task Sequence "WSRV-BASE" with a new Product Key.

## Parameters

### -JSON

The Lab Details JSON File.

|  | |
|---|---|
| Type:    | Object |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -TaskSequenceID

The Task Sequence ID

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -SearchString

The Search String for the Task Sequence

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -WinVerBuild

The Windows Version to update to

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |