function Get-NutanixApiError {

<#
    .SYNOPSIS
    Decodes a Nutanix Api call error.

    .DESCRIPTION
    This function will take in an Error message and Decode an Api call error.
    
    .PARAMETER ErrorMessage
    Specifies the Error Message to decode

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the relevant Api Path

    .EXAMPLE
    PS> Get-NutanixApiError -Error $Error 
    Decodes the Api Error call for $Error.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Get-NutanixApiError.md

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)]$ErrorMessage
    )

    begin {

        # Set strict mode and initial return value
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Decode the Api Error
        if(test-path variable:\ErrorMessage.ErrorDetails.Message){
            $ErrorJSON = $ErrorMessage.ErrorDetails.Message | ConvertFrom-Json
        } else {
            $ErrorReturn = $ErrorMessage
        }
        
        # Check for active web session
        if(test-path variable:\ErrorJSON.data.error.validationErrorMessages.message){
            $Return = $ErrorJSON.data.error.validationErrorMessages.message
        } else {
            $Return = $ErrorReturn
        }

    } # process

    end {

        # Return Error
        return "Api Error: $($Return)"

    } # end

}
