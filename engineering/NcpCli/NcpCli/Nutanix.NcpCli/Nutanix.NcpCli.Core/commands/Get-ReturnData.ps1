function Get-ReturnData {
<#
    .SYNOPSIS
    Checks for a $null or blank variable.

    .DESCRIPTION
    This function will check a variable for either a $null value or an empty string.
    
    .PARAMETER Result
    Specifies the Result Data to return.

    .PARAMETER CmdLet
    Specifies the function name that called this Return Data.

    .INPUTS
    None.

    .OUTPUTS
    Returns either the data or a warning error depending on whats passed into the function.

    .EXAMPLE
    PS> Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name
    Gets the return data based on the information in $Result.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ReturnData.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)]$Result,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)]$CmdLet
    )

    begin{

        # Set strict mode 
        Set-StrictMode -Version Latest

    }

    process {

        if($Result -like "Api Error*"){
            write-verbose "$($CmdLet) - Api error found, returning result"
            write-warning "$($CmdLet) - $($Result)"
        } else {
            if($Result -eq "No data found"){
                write-verbose "$($CmdLet) - Api success but no data found"
            } else {
                write-verbose "$($CmdLet) - Api success, returning data"
            }
        }

    } # process

    end {

        # Return the result
        Return $Result

    } # end

}
    