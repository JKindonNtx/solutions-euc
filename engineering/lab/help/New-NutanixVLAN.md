# New-NutanixVLAN

Creates a new VLAN.

## Syntax

```PowerShell
New-NutanixVLAN
    [-IP] <String>
    [-UserName] <String>
    [-Password] <String>
    [-VLAN] <String>
    [-VLANName] <String>
    [<CommonParameters>]
```

## Description

This function will create a new VLAN on a Nutanix Cluster.

## Examples

### EXAMPLE 1:

```PowerShell
New-NutanixVLAN -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -VLAN "164" -VLANName "VLAN164"
```

Creates a new VLAN with the ID 164 and Name VLAN164

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

### -VLAN

The VLAN ID.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -VLANName

The VLAN Name.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
