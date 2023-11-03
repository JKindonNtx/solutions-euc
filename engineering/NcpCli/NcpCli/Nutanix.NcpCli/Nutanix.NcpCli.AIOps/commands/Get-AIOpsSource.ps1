function Get-AIOpsSource {

<#
    .SYNOPSIS
    Gets the AI Ops Sources from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the AI Ops Sources available.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns Nutanix Cluster AIOps Sources available.

    .EXAMPLE
    PS> Get-AIOpsSource
    Gets the current AIOps Source from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-AIOpsSource.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param ()

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {
            
        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($AiOpsNameSpace)/$($AIOpsApiVersion)/$($ModuleStats)/$($AIOpsResourceSources)"
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
