# Get-NutanixCluster

Gets AHV Cluster Details.

## Syntax

```PowerShell
Get-NutanixCluster
    [-IP] <String>
    [-UserName] <String>
    [-Password] <String>
    [<CommonParameters>]
```

## Description

This function will connect to and gather information about an AHV cluster.

## Examples

### EXAMPLE 1:

```PowerShell
Get-NutanixCluster -IP "10.10.10.10" -UserName "admin" -Password "nutanix"
```

Gets the Nutanix Cluster details from 10.10.10.10

### EXAMPLE 2:

```PowerShell
Get-NutanixCluster -IP "10.10.10.10" -User "admin" -Pass "nutanix"
```

Gets the Nutanix Cluster details from 10.10.10.10 using the Alias names for UserName and Password


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