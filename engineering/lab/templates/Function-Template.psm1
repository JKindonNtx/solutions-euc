function Function-Template {
<#
    .SYNOPSIS
    Brief description of the function.

    .DESCRIPTION
    Detailed Decription of what the function will do.
    
    .PARAMETER Parameter1
    Parameter 1 description

    .PARAMETER Parameter2
    Parameter 2 description

    .EXAMPLE
    PS> Function-Template -Parameter1 "1" -Parameter2 "2"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    Task variable containing the output of the Invoke-RestMethod command run - CHANGE THIS IF RETURNING SOMETHING ELSE

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Function-Template.md - UPDATE THIS TO POINT TO YOUR HELP FILE

    .NOTES
    Author          Version         Date            Detail
    Name            v1.0.0          Date            Function creation
    Name            v1.0.1          Date            Function Updates
#>


    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$Parameter1,

        [Parameter(
            Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [system.string[]]$Parameter2
    )

    Begin
    {
        # Place for Function Setup Code
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":Parameter1: $Parameter1" 
        Write-Host (Get-Date)":Parameter2: $Parameter2" 

        # Place for Function Execution Code
        Install-Module -Name Posh-SSH -Force

    } # Process
    
    End
    {
        # Place for Returning Parameters / Objects
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $Parameter1
    } # End

} # Function-Template
