Function Update-Slack {
    <#
    .Synopsis
        This function will send an update to Slack.
    .Description
        This function will send an update to Slack. 
    #>

    Param(
        [String]$Message,
        [String]$Slack
    )
    
    $body = ConvertTo-Json @{
        username = "LoginVSI automation factory"
        attachments = @(
            @{
                fallback = "Finished installing VM template from Docker."
                color = "#36a64f"
                pretext = "*Finished installing VM template from Docker*"
                title = $VMName
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