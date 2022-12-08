# Update-Slack

Updates a Slack Channel.

## Syntax

```PowerShell
Update-Slack
    [-Message] <String>
    [-Slack] <String>
    [<CommonParameters>]
```

## Description

This function will Update a slack channel with the status of the automation tasks.

## Examples

### EXAMPLE 1:

```PowerShell
Update-Slack -Message "Message" -Slack "https://slack/api"
```

Sends a message to the relevant slack channel.

## Parameters

### -Message

The message to send.

|  | |
|---|---|
| Type:    | Object |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

### -Slack

The Slack Hook Uri

|  | |
|---|---|
| Type:    | String |
| Default Value: | None |
| Accept pipeline input: | True |
| Accept wildcard characters: | False |
| Mandatory: | True |

