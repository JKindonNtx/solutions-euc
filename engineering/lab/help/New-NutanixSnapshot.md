# New-NutanixVLAN

Create a VM Snapshot.

## Syntax

```PowerShell
New-NutanixSnapshot
    [-IP] <String>
    [-UserName] <String>
    [-Password] <String>
    [-VMUUID] <String>
    [-SnapName] <String>
    [<CommonParameters>]
```

## Description

This function will create a new snapshot of a Virtual Machine in a Nutanix Cluster.

## Examples

### EXAMPLE 1:

```PowerShell
New-NutanixSnapshot -IP "10.10.10.10" -UserName "admin" -Password "Password" -VMUUID "{UUID}" -SnapName "Snapshot_VM"
```

Creates a new Snapshot on the Virtual Machine called "Snapshot_VM"

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

### -VMUUID

The UUID of the Virtual Machine.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -SnapName

The Snapshot Name.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
