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
    
    Param(
        $ImageURL,
        $SlackToken,
        $SlackChannel,
        $SlackTitle,
        $SlackComment
    )

    if(!(get-module | where-object {$_.Name -eq "PSSlack" })) {
        install-module PSSlack -Scope CurrentUser -allowclobber -Confirm:$false -Force
        import-module PSSlack
    }

    Send-SlackFile -Channel $SlackChannel -path $ImageURL -Token $SlackToken -Title $SlackTitle -Comment $SlackComment
} 
    