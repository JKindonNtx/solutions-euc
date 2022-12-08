# Set-NutanixVMPower

Changes the Power State of a VM.

## Syntax

```PowerShell
Set-NutanixVMPower
    [-IP] <String>
    [-UserName] <String>
    [-Password] <String>
    [-APIpath] <String>
    [-Action] <String>
    [<CommonParameters>]
```

## Description

This function will ceither switch ON or OFF the power for a Virtual Machine.

## Examples

### EXAMPLE 1:

```PowerShell
Set-NutanixVMPower -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -APIPath "power" -Action "OFF"
```

Changes the power state of a Virtual Machine to OFF.

## Parameters

### -IP

The Nutanix Cluster IP to connect to.

|  | |
|---|---|
| Type:    | String |
| Aliases: | ClusterIP |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -UserName

The user name to use for the connection.
|  | |
|---|---|
| Type:    | String |
| Aliases: | User |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -Password

The password for the user name.
|  | |
|---|---|
| Type:    | String |
| Aliases: | Pass |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -APIpath

The Power API Path.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -Action

The action to take (ON/OFF)
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
