function Get-FlowNetworkSecurityPolicy {
<#
    .SYNOPSIS
    Gets the Flow Network Security Policy from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the Network Security Policies.

    .PARAMETER NetworkSecurityPolicyExtID
    (Optional) Specifies the UUID of the Flow Network Security Policy you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Flow Network Security policies or a specific policy depending on the variables passed in.

    .EXAMPLE
    PS> Get-FlowNetworkSecurityPolicy 
    Gets the current Flow Network Security Policy from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-FlowNetworkSecurityPolicy -NetworkSecurityPolicyExtID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Flow Network Security Policy from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-FlowNetworkSecurityPolicy.md
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$NetworkSecurityPolicyExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($FlowNameSpace)/$($FlowApiVersion)/$($ModuleConfig)/$($FlowResourceNetworkSecurityPolicies)"

        # If specific value is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $NetworkSecurityPolicyExtID)){
            $ApiPath = "$($ApiPath)/$($NetworkSecurityPolicyExtID)"
        } 
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
