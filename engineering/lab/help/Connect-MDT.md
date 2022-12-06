# Connect-MDT

Connects a local mount point to a MDT Server.

## Syntax

```PowerShell
Connect-MDT
    [-UserName] <String>
    [-Password] <String>
    [-Domain] <String>
    [-MdtServerIp] <String>
    [-ShareName] <String>
    [<CommonParameters>]
```

## Description

This function will create a local mount point then mount a connection to a Microsoft Deployment Server.

## Examples

### EXAMPLE 1:

```PowerShell
Connect-MDT -Username "User" -Password "passw0rd1!" -Domain "domain" -MdtServerIP "10.11.12.13" -ShareName "MDT$"
```

Connects the MDT share to the local mnt/mdt mount directory

### EXAMPLE 2:

```PowerShell
Connect-MDT -User "User" -Pass "passw0rd1!" -Domain "domain" -MdtServerIP "10.11.12.13" -ShareName "MDT$"
```

Connects the MDT share to the local mnt/mdt mount directory


## Parameters

### -Username

Specifies the user name to mount the drive as.

|  | |
|---|---|
| Type:    | String |
| Aliases: | User |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -Password

Specifies the password for the user that you are mounting the drive with.
|  | |
|---|---|
| Type:    | String |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -Domain

Specifies the domain to which the user belongs.

|  | |
|---|---|
| Type:    | String |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -MdtServerIP

Specifies the MDT server IP that you will be connecting to, we use an IP to ensure connectivity in the event that DNS is not operational.

|  | |
|---|---|
| Type:    | String |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -ShareName

Specifies the share name on the MDT server to mount to.

|  | |
| Type:    | String |
| Position: | Named |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |