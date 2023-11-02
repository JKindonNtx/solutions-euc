function Get-FlowNetworkSecurityPolicy {

<#
    .SYNOPSIS
    Gets the Flow Network Security Policy from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Network Security Policy.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER UUID
    (Optional) Specifies the UUID of the Flow Network Security Policy you wish to return

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the query result and either the data from the query or the error message

    .EXAMPLE
    PS> Get-FlowNetworkSecurityPolicy -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
    Gets the current Flow Network Security Policy from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-FlowNetworkSecurityPolicy -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -UUID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Flow Network Security Policy from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-FlowNetworkSecurityPolicy.md
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$UUID,
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        try {
            
            # Build Api Reference
            write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api Reference"
            if($null -ne $UUID){
                $ApiRoot = (Get-NutanixApiPath -NameSpace "Flow.NetworkSecurityPolicy")
                $ApiPath = "$($ApiRoot)/$($UUID)"
            } else {
                $ApiPath = (Get-NutanixApiPath -NameSpace "Flow.NetworkSecurityPolicy")
            }
            write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Api: $($ApiPath)"

            # Execute Api Call
            write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query targetting $($PrismIP)"
            Invoke-NutanixApiCall -PrismIP $PrismIP -PrismUserName $PrismUserName -PrismPassword $PrismPassword -ApiPath $ApiPath

        } catch {

            # Api call failed - output the error
            write-warning "$($PSCmdlet.MyInvocation.MyCommand.Name) - Api call failed: $_"

        }

    } # process

    end {} # end

}
