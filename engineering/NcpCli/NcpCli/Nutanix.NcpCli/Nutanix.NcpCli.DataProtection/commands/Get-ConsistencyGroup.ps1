function Get-ConsistencyGroup {

<#
    .SYNOPSIS
    Gets the Consistency Groups from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Data Protection Consistency Groups.

    .PARAMETER ConsistencyGroupExtID
    (Optional) Specifies the UUID of the Consistency Groups you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns all the Data Protection Consistency Groups from Prism Central.

    .EXAMPLE
    PS> Get-ConsistencyGroup
    Gets the current Consistency Groups from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-ConsistencyGroup -ConsistencyGroupExtID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Consistency Group from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ConsistencyGroup.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$ConsistencyGroupExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($DataProtectionNameSpace)/$($DataProtectionApiVersion)/$($ModuleConfig)/$($DataProtectionResourceConsistencyGroups)"

        # If specific value is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $ConsistencyGroupExtID)){
            $ApiPath = "$($ApiPath)/$($ConsistencyGroupExtID)"
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
