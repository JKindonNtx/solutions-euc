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
    End
    {
        Write-Host (Get-Date)":Finishing 'Get-GitHubInfo'" 
        Return $GitHubDetails
    }
    }
