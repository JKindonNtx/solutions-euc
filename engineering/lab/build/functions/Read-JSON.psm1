<#
.Synopsis
    Reads values from JSON File
.DESCRIPTION
    This function will read and populate all the variables from the supplied JSON file
.EXAMPLE
    Read-JSON -JSONFile "CreateVM.json"
.INPUTS
    JSONFile - The JSON File to read the variables from
.NOTES
    David Brett      28/11/2022         v1.0.0             Function Creation
.FUNCTIONALITY
    This is used to build a variable set for use within the remainder of the scripting framework
#>

function Read-JSON
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  PositionalBinding=$false)]
    Param
    (
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true
                   )]
        [string[]]
        $JSONFile
    )

    Begin
    {
        Write-Host (Get-Date)":Starting 'Read-JSON'" 
    }

    Process
    {
        # Display function parameters
        Write-Host (Get-Date)":JSON file: $JSONFile" 

        # Check for valid JSONN File and read into an object
        if(Test-Path -Path $JSONFile) { $JSON = Get-Content -Path $JSONFile -Raw | ConvertFrom-Json }
    }
    
    End
    {
        Write-Host (Get-Date)":Finishing 'Read-JSON'" 
        Return $JSON
    }
}