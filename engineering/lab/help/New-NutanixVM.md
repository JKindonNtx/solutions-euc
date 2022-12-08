# New-NutanixVM

Creates a Virtual Machine.

## Syntax

```PowerShell
New-NutanixVM
    [-JSON] <Object>
    [-Name] <String>
    [-VMtimezone] <String>
    [-StorageUUID] <String>
    [-ISOUUID] <String>
    [-VLANUUID] <String>
    [<CommonParameters>]
```

## Description

This function will create a new Virtual Machine on a Nutanix Cluster.

## Examples

### EXAMPLE 1:

```PowerShell
New-NutanixVM -JSON $JSON -Name "VM" -VMTimeZone "GMT" - StorageUUID "{UUID}" -ISOUUID "{UUID}" -VLANUUID "{UUID}"
```

Creates a new Virtual Machine on the Nutanix Cluster

## Parameters

### -JSON

The Object containing all the Virtual Machine config details.

|  | |
|---|---|
| Type:    | Object |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -Name

The VM Name.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -VMtimezone

The Time Zone for the VM.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -StorageUUID

The Storage UUID.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -ISOUUID

The ISO UUID.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -VLANUUID

The VLAN UUID.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
