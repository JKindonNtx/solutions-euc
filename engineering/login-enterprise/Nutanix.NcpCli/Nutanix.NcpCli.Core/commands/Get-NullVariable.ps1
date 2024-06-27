function Get-NullVariable {
<#
    .SYNOPSIS
    Checks for a $null or blank variable.

    .DESCRIPTION
    This function will check a variable for either a $null value or an empty string.
    
    .PARAMETER Check
    Specifies the variable to check.

    .INPUTS
    None.

    .OUTPUTS
    Returns an $true or $false based on the contents of the $Check variable.

    .EXAMPLE
    PS> Get-NullVariable -Check $VariableName
    Checks the $VariableName variable for a $null or blank value.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-NullVariable.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$Check
    )

    begin{

        # Set strict mode 
        Set-StrictMode -Version Latest

    }

    process {

        if(($null -eq $Check) -or ($Check -eq "")){
            $Return = $true
        } else {
            $Return = $false
        }

    } # process

    end {

        # Return the result
        Return $Return

    } # end

}
    