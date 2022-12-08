# Get-AnsiblePlaybooks

Gathers a list of available Ansible Playbooks.

## Syntax

```PowerShell
Get-AnsiblePlaybooks
    [-SearchString] <String>
    [-AnsiblePath] <String>
    [<CommonParameters>]
```

## Description

This function will gather a list of Ansible Playbooks available in the build lab repository.

## Examples

### EXAMPLE 1:

```PowerShell
Get-AnsiblePlaybooks -SearchString "SRV" -AnsiblePath "/ansible/"
```

Gets a list of available Ansible Playbooks from /ansible for the Server operating system

### EXAMPLE 2:

```PowerShell
Get-AnsiblePlaybooks -Search "W10" -Path "/ansible/"
```

Gets a list of available Ansible Playbooks from /ansible for the Windows 10 operating system


## Parameters

### -SearchString

The search string to check for the Ansible Playbook prefix against.

|  | |
|---|---|
| Type:    | String |
| Aliases: | Search |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -AnsiblePath

The path in the repository for the Ansible Playbooks.
|  | |
|---|---|
| Type:    | String |
| Aliases: | Path |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

