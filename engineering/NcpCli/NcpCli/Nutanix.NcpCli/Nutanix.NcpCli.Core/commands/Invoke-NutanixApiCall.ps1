function Invoke-NutanixApiCall {
<#
    .SYNOPSIS
    Executes an API call against a Nutanix Prism Central instance.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will either return the result data for the call or the error message as to why the call failed.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER ApiPath
    Specifies the Prism Central Api Path to query

    .PARAMETER Body
    (Optional) Specifies the Body to send to the Api Query

    .PARAMETER ContentType
    Specifies the Content Type for the Api Call

    .PARAMETER Method
    Specifies the Method you with to use for the query (POST, GET, PUT, DELETE)

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the query result and either the data from the query or the error message

    .EXAMPLE
    PS> $Alerts = Invoke-NutanixApiCall -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ApiPath "prism/v4.0.a1/alerts"
    Gets the current alerts from the Prism Central Appliance.

    .EXAMPLE
    PS> Invoke-NutanixApiCall -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ApiPath "prism/v4.0.a2/config/categories"
    Gets the categories from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Invoke-NutanixApiCall.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$ApiPath,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$Body,
        [Parameter()][System.String]$ContentType = 'application/json',
        [Parameter()][ValidateSet("POST", "GET", "PUT", "DELETE")]$Method = "GET"
    )

    begin {

        # Build the Api Call authorization header
        $header = @{
            Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($PrismUserName) + ":" + $($PrismPassword)))
        }

    } # begin

    process {

        try {
            
            # Set blank error message
            $ErrorMessage = ""

            # Build the full Api Uri
            $Uri = "https://$($PrismIP):9440$($ApiPath)"

            # Execute the Api query and catch any errors
            if ($null -ne $Body) {
                try {
                    $ApiData = Invoke-RestMethod -Body $Body -Method $Method -Uri $Uri -Headers $Header -SkipCertificateCheck -ErrorAction SilentlyContinue  
                } catch {
                    $ErrorMessage = Get-NutanixApiError -ErrorMessage $_
                }
            } else {
                try {
                    $ApiData = Invoke-RestMethod -Method $Method -Uri $Uri -Headers $Header -SkipCertificateCheck
                } catch {
                    $ErrorMessage = Get-NutanixApiError -ErrorMessage $_
                }
            }

        } catch {  
            $ErrorMessage = Get-NutanixApiError -ErrorMessage $_

        }
        
    } # process

    end {

        if($ErrorMessage -eq ""){
            if([bool]($ApiData.PSobject.Properties.name -eq "data")) {
                return $ApiData.data
            } else {
                return "No data found"
            }
        } else {
            return $ErrorMessage
        }
        
    } # end

}
