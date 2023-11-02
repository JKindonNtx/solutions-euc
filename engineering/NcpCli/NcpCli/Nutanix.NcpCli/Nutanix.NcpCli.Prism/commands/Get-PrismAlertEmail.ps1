function Get-PrismAlertEmail {

<#
    .SYNOPSIS
    Gets the Alert Email Detail from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the Alert Email Configuration.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the query result and either the data from the query or the error message

    .EXAMPLE
    PS> Get-PrismAlertEmail -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
    Gets the current Alert Email Configuration from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-PrismAlertEmail.md
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword
    )

    begin {

        # Set strict mode and initial return value
        Set-StrictMode -Version Latest

    } # begin

    process {

        try {
            write-verbose "Setting Tasks Api Reference"
            $ApiPath = "/prism/v4.0.a2/serviceability/alerts/email-config"

            write-verbose "Calling Api data from Prism"
            Invoke-NutanixApiCall -PrismIP $PrismIP -PrismUserName $PrismUserName -PrismPassword $PrismPassword -ApiPath $ApiPath

        } catch {

            write-warning "Api call failed: $_"

        }

    } # process

    end {} # end

}
