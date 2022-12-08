# Set-NutanixvTPM

Set a vTPM up on the VM.

## Syntax

```PowerShell
Set-NutanixvTPM
    [-ClusterIP] <String>
    [-CVMSSHPassword] <String>
    [-VMname] <String>
    [<CommonParameters>]
```

## Description

This function will set up a vTPM on a Virtual Machine.

## Examples

### EXAMPLE 1:

```PowerShell
Set-NutanixvTPM -ClusterIP "10.10.10.10" -CVMSSHPassword "password" -VMname "VM"
```

Adds a vTPM to the machine "VM".

## Parameters

### -ClusterIP

The Nutanix Cluster IP to connect to.

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -CVMSSHPassword

The password for the CVM.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -VMname

The VM name.
|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |
