function Update-VSISlackImage {
    <#
    .SYNOPSIS
    Posts the Grafana image into slack
    
    .DESCRIPTION
    This function will post the Grafana image into slack
        
    .PARAMETER ImageURL
    Image to Post
    
     .PARAMETER SlackToken
    The Token for posting the image

    .PARAMETER SlackChannel
    The Channel to post the image to

    .PARAMETER SlackTitle
    The Title for the file

    .PARAMETER SlackComment
    The Comment on the file in the Slack message

#>
    [CmdletBinding()]

    Param (
        $ImageURL,
        $SlackToken,
        $SlackChannel,
        $SlackTitle,
        $SlackComment
    )

    if (!(get-module | where-object { $_.Name -eq "PSSlack" })) {
        try {
            install-module PSSlack -Scope CurrentUser -allowclobber -Confirm:$false -Force -ErrorAction Stop | Out-Null
            import-module PSSlack -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Log -Message $_ -Level Error
        }
            
    }

    $UpdateSlackFile = Send-SlackFile -Channel $SlackChannel -path $ImageURL -Token $SlackToken -Title $SlackTitle -Comment $SlackComment

}
