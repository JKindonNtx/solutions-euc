function Get-AIOpsEntities {
<#
    .SYNOPSIS
    Gets the AI Ops Entities from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the AIOps Entities available.

    .PARAMETER SourceExtID
    Specifies the Source ExtID of the Entity you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the AIOps entities available given a particular source.

    .EXAMPLE
    PS> Get-AIOpsEntities -SourceExtID "db293e8a-5770-c3c7-4213-85dbbc1d3679"
    Gets the AIOps Entities from the Prism Central Appliance for SourceExtID db293e8a-5770-c3c7-4213-85dbbc1d3679.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-AIOpsEntities.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$SourceExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($AiOpsNameSpace)/$($AIOpsApiVersion)/$($ModuleStats)/$($AIOpsResourceSources)/$($SourceExtID)/$($AIOpsResourceEntityTypes)"
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
