function Update-VSISlack {
    <#
    .SYNOPSIS
    Updates a Slack Channel

    .DESCRIPTION
     This function will Update a slack channel with the status of the automation tasks

    .PARAMETER Message
    The message to send

    .PARAMETER Slack
    The Slack Channel to update

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    None

    .EXAMPLE
    PS> Update-VSISlack -Message "Message" -Slack "https://slack/api"

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Update-Slack.md

    .NOTES
    Author          Version         Date            Detail
    David Brett     v1.0.0          28/11/2022      Function creation

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValueFromPipeline = $true, ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$Slack,
        [Parameter(ValueFromPipeline = $true, ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$Message
    )

    Write-Log -Message "Message: $Message" -Level Info
    Write-Log -Message "Slack: $Slack" -Level Info

    $body = ConvertTo-Json -Depth 4 @{
        username    = "Login Enterprise Automation"
        attachments = @(
            @{
                fallback = "Login Enterprise Slack Integration."
                color    = "#36a64f"
                pretext  = "*Login Enterprise Integration*"
                title    = "Login Enterprise Automation update"
                text     = $Message  
            }
        )
    }
    $RestError = $null
    Try {
        Invoke-RestMethod -uri $Slack -Method Post -body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
    } 
    Catch {
        $RestError = $_
        Write-Log -Message "Failed to update Slack" -Level Warn
        Write-Log -Message $RestError -Level Warn
    }
}
