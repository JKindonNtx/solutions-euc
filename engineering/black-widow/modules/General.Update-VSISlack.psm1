function Update-VSISlack {
<#
    .SYNOPSIS
    Updates a Slack Channel

    .DESCRIPTION
    This function will Update a slack channel with the status of the automation tasks.
    
    .PARAMETER Message
    The message to send

    .PARAMETER Slack
    The Slack Channel to update

    .EXAMPLE
    PS> Update-VSISlack -Message "Message" -Slack "https://slack/api"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    None

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Update-Slack.md

    .NOTES
    Author          Version         Date            Detail
    David Brett     v1.0.0          28/11/2022      Function creation
#>


    [CmdletBinding()]

    Param
    (
        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        $Slack,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        $Message
    )

    Begin
    {
        Set-StrictMode -Version Latest
    } # Begin

    Process
    {
        # Display Function Parameters

        $body = ConvertTo-Json -Depth 4 @{
            username = "Black Widow Automation"
            attachments = @(
                @{
                    fallback = "Black Widow Slack Integration."
                    color = "#36a64f"
                    pretext = "*Black Widow Integration*"
                    title = "Black Widow Automation update"
                    text = $Message  
                }
            )
        }
        $RestError = $null
        Try {
            Invoke-RestMethod -uri $Slack -Method Post -body $body -ContentType 'application/json' | Out-Null
        } Catch {
            $RestError = $_
        }
    }
    
    End
    {
    } # End

} # Update-VSISlack
