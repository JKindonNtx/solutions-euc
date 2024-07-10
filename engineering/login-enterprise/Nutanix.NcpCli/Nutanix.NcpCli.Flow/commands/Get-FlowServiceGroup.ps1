function Get-FlowServiceGroup {
<#
    .SYNOPSIS
    Gets the Flow Service Groups from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Flow Service Groups.

    .PARAMETER ServiceGroupExtID
    (Optional) Specifies the UUID of the Flow Service Groups you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Flow Service Groups or a specific group depending on the variables passed in.

    .EXAMPLE
    PS> Get-FlowServiceGroup 
    Gets the current Flow Service Group from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-FlowServiceGroup -ServiceGroupExtID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Flow Service Group from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-FlowServiceGroup.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$ServiceGroupExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($FlowNameSpace)/$($FlowApiVersion)/$($ModuleConfig)/$($FlowResourceServiceGroups)"

        # If specific value is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $ServiceGroupExtID)){
            $ApiPath = "$($ApiPath)/$($ServiceGroupExtID)"
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
