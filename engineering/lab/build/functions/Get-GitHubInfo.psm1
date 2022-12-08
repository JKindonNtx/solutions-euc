function Get-GitHubInfo {
<#
    .SYNOPSIS
    Gets the GitHub Information

    .DESCRIPTION
    This function will get the GitHub information for the user that currently has the repo open.
    
    .EXAMPLE
    PS> Get-GitHubInfo

    .INPUTS
    None

    .OUTPUTS
    None

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Get-GitHubInfo.md

    .NOTES
    Author          Version         Date            Detail
    Kees Baggerman  v1.0.0          06/12/2022      Function Creation
    David Brett     v1.0.1          06/12/2022      Updated Parameter definition
                                                    Updated function header to include MD help file
                                                    Changed Write-Host from hardcoded function name to $($PSCmdlet.MyInvocation.MyCommand.Name)

#>


    [CmdletBinding()]

    Param
    ()

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # Begin


    Process
    {
        Write-Host (Get-Date)":Gathering Github configuration" 

        # Collecting the complete github configuration
        $GitHubInfo = git config --list    

        # Create Custom PS Object
        $GitHubDetails = New-Object -TypeName psobject 

        # Loop through Git output and grab Username and Email
        foreach ($GitLine in $GitHubInfo) { 
            if($GitLine -like "user.name*") { 
                $GitHubDetails | Add-Member -MemberType NoteProperty -Name "UserName" -Value $GitLine.Split('=')[1]
            } 
            if($GitLine -like "user.email*") { 
                $GitHubDetails | Add-Member -MemberType NoteProperty -Name "Email Address" -Value $GitLine.Split('=')[1]
            } 
        }
    } # End

    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $GitHubDetails
    } # End

} # Get-GitHubInfo
