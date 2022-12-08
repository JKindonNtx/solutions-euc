# Remove-NutanixCDROM

Removes a CD-ROM.

## Syntax

```PowerShell
Remove-NutanixCDROM
    [-IP] <String>
    [-UserName] <String>
    [-Password] <String>
    [-VMUUID] <String>
    [<CommonParameters>]
```

## Description

This function will remove the CD-ROM drive from a Virtual Machine on the Nutanix Cluster.

## Examples

### EXAMPLE 1:

```PowerShell
Remove-NutanixCDROM -IP "10.10.10.10" -UserName "admin" -Password "Password" -VMUUID "{UUID}"
```

Removes a CDROM from a Virtual Machine on the Nutanix Cluster

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

The Virtual Machine UUID.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
