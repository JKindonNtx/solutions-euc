# New-NutanixLocalUser

Adds a local user to a Nutanix Cluster.

## Syntax

```PowerShell
New-NutanixLocalUser
    [-ClusterIP] <String>
    [-CVMSSHPassword] <String>
    [-LocalUser] <String>
    [-LocalPassword] <String>
    [<CommonParameters>]
```

## Description

This function will create a new Local User on the cluster for build and config.

## Examples

### EXAMPLE 1:

```PowerShell
New-NutanixLocalUser -IP "10.10.10.10" -CVMSSHPassword "password" -LocalUser $Username -LocalPassword "Password"
```

Create a new Local User on the Nutanix Cluster

## Parameters

### -ClusterIP

The Nutanix Cluster IP to connect to.

|  | |
|---|---|
| Type:    | String |
| Aliases: | ClusterIP |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -CVMSSHPassword

The SSH Password for the CVM.

|  | |
|---|---|
| Type:    | String |
| Aliases: | User |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -LocalUser

The local user name.

|  | |
|---|---|
| Type:    | String |
| Aliases: | Pass |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -LocalPassword

The password for the local user.

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
