# New-NutanixStorageContainer

Creates a new Storage Container.

## Syntax

```PowerShell
New-NutanixStorageContainer
    [-IP] <String>
    [-UserName] <String>
    [-Password] <String>
    [-Container] <String>
    [<CommonParameters>]
```

## Description

This function will create a new storage cluster on a Nutanix Cluster.

## Examples

### EXAMPLE 1:

```PowerShell
New-NutanixStorageContainer -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -Container "VDI" 
```

Creates a new Storage Container called VDI

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

### -Container

The name for the Storage Container.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
