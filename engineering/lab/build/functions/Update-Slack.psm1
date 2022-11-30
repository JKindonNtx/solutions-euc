<#
.Synopsis
    Update Slack
.DESCRIPTION
    Update Slack
.EXAMPLE
    Update-Slack -Message "Message" -Slack "https://slack/api"
.INPUTS
    Message - The message to send
    Slack - The Slack API
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Update Slack
#>

function Update-Slack
{
    Param
    (
        $Message,
        $Slack
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Update-Slack'" 
    }

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":Message: $Message" 
        Write-Host (Get-Date)":Slack: $Slack" 

        $body = ConvertTo-Json -Depth 4 @{
            username = "LoginVSI Automation Factory"
            attachments = @(
                @{
                    fallback = "Finished installing VM template from Docker."
                    color = "#36a64f"
                    pretext = "*Finished installing VM template from Docker*"
                    title = "Automation Complete"
                    text = $Message  
                }
            )
        }
        $RestError = $null
        Try {
            Invoke-RestMethod -uri $Slack -Method Post -body $body -SkipCertificateCheck -ContentType 'application/json' | Out-Null
        } Catch {
            $RestError = $_
        }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Update-Slack'" 
    }
}
