<#
.Synopsis
    Get Github details from the local GH repo
.DESCRIPTION
    Get local Github profle details
.EXAMPLE
    Get-GitHubInfo -UserName -UserEmail
.INPUTS
    UserName - The local user name 
    UserEmail - The email registered for the local GH repo
.NOTES
    Kees Baggerman      06/12/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    Get Github details from the local GH repo
#>

function Get-GitHubInfo
{
    [CmdletBinding(SupportsShouldProcess=$false, 
                  PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$false
            )]
        [string[]]
        $UserName,
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$false
            )]
        [string[]]
        $UserEmail
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Get-GitHubInfo'" 
    }

    Process
    {
        Write-Host (Get-Date)":Gathering Github configuration" 

        # Collecting the complete github configuration
        $GitHubInfo = git config --list        
      
        $GitHubDetails = New-Object -TypeName psobject 

        # Build the object to return
        $GitHubDetails | Add-Member -MemberType NoteProperty -Name "Username" -Value $GitHubInfo[5].Split('=')[1]
        $GitHubDetails | Add-Member -MemberType NoteProperty -Name "Email Address" -Value $GitHubInfo[6].Split('=')[1]
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Get-GitHubDetails'" 
        Return $GitHubDetails
    }
}