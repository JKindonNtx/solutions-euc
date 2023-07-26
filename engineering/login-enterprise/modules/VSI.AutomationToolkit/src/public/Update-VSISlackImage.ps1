function Update-VSISlackImage {
    <#
        .SYNOPSIS
        Posts the Grafana image into slack
    
        .DESCRIPTION
        This function will post the Grafana image into slack
        
        .PARAMETER ImageURL
        Image to Post
    
        .PARAMETER SlackToken
        The Path to the test results

        .PARAMETER SlackChannel
        The Path to the test results

        .PARAMETER SlackComment
        The Path to the test results
    #>
    
    Param(
        $ImageURL,
        $SlackToken,
        $SlackChannel,
        $SlackComment
    )

    if(!(get-module | where-object {$_.Name -eq "PSSlack" })) {
        install-module PSSlack -allowclobber -force
        import-module PSSlack
    }

    Send-SlackFile -Channel $SlackChannel -path $ImageURL -Token $SlackToken -Title $SlackComment
} 
    