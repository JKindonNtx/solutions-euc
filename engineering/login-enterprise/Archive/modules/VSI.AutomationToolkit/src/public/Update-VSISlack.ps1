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
        Write-Log "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Log "Message: $Message" 
        Write-Log "Slack: $Slack" 

        $body = ConvertTo-Json -Depth 4 @{
            username = "Login Enterprise Automation"
            attachments = @(
                @{
                    fallback = "Login Enterprise Slack Integration."
                    color = "#36a64f"
                    pretext = "*Login Enterprise Integration*"
                    title = "Login Enterprise Automation update"
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
        Write-Log "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # End

} # Update-VSISlack
