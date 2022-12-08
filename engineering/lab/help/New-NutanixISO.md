# New-NutanixISO

Upload a new ISO file to a Nutanix Cluster.

## Syntax

```PowerShell
New-NutanixISO
    [-IP] <String>
    [-UserName] <String>
    [-Password] <String>
    [-StorageUUID] <String>
    [-ISOurl] <String>
    [-ISOname] <String>
    [<CommonParameters>]
```

## Description

This function will take an ISO image from a web server passed in and upload it to a Nutanix Cluster image library for use within that cluster.

## Examples

### EXAMPLE 1:

```PowerShell
New-NutanixISO -IP "10.10.10.10" -UserName "admin" -Password "nutanix" -StorageUUID "1234223-321221" -ISOUrl "https://webserver/" -ISOName "build.iso" 
```

Upload a new ISO to the cluster called build.iso

### EXAMPLE 2:

```PowerShell
New-NutanixISO -IP "10.10.10.10" -User "admin" -Pass "nutanix" -StorageUUID "1234223-321221" -ISOUrl "https://webserver/" -ISOName "build.iso"
```

Upload a new ISO to the cluster called build.iso using the alias parameter values


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

### -StorageUUID

The UUID for the storage container to upload the ISO to.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -ISOurl

The URL to get the ISO from to upload.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -ISOname

The name for the ISO file.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |