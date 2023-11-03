function Get-FlowAddressGroup {
<#
    .SYNOPSIS
    Gets the Flow Address Groups from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Flow Address Groups.

    .PARAMETER AddressGroupExtID
    (Optional) Specifies the UUID of the Flow Address Group you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Flow Address Groups or a specific Address Group dependant on the parameters passed in.

    .EXAMPLE
    PS> Get-FlowAddressGroup
    Gets the current Flow Address Group from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-FlowAddressGroup -AddressGroupExtID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Flow Address Group from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-FlowAddressGroup.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$AddressGroupExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($FlowNameSpace)/$($FlowApiVersion)/$($ModuleConfig)/$($FlowResourceAddressGroups)"

        # If specific value is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $AddressGroupExtID)){
            $ApiPath = "$($ApiPath)/$($AddressGroupExtID)"
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
