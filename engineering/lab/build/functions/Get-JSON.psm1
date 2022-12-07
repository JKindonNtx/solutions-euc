function Get-JSON {
<#
    .SYNOPSIS
    Reads values from JSON File.

    .DESCRIPTION
    This function will take in a JSON file and read the contents into a variable.
    
    .PARAMETER JSONFile
    The JSON File to read the variables from

    .EXAMPLE
    PS> Get-JSON -JSONFile "CreateVM.json"

    .INPUTS
    This function will take inputs via pipeline by property

    .OUTPUTS
    PSCustomObject containing the contants of the JSON File

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/help/Get-JSON.md

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
        [system.string[]]$JSONFile
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # Begin


    Process
    {
        # Display function parameters
        Write-Host (Get-Date)":JSON file: $JSONFile" 

        # Check for valid JSONN File and read into an object
        if(Test-Path -Path $JSONFile) { $JSON = Get-Content -Path $JSONFile -Raw | ConvertFrom-Json } else { Write-Host (Get-Date)":Cannot Find JSON file: $JSONFile"; Exit }
    } # Process
    
    End
    {
        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        Return $JSON
    } # End

} # Get-JSON