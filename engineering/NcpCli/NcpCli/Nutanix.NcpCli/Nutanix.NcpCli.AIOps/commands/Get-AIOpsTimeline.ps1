function Get-AIOpsTimeline {

<#
    .SYNOPSIS
    Gets the AI Ops Timeline Data from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the AI Ops Timeline Data available.

    .PARAMETER SourceExtID
    Specifies the Source ExtID of the Entity you wish to return the timeline data for

    .PARAMETER EntityExtID
    Specifies the Entity ExtID of the Entity you wish to return the timeline data for

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the timeline data for a given entity based on a source type.

    .EXAMPLE
    PS> Get-AIOpsTimeline -SourceExtID $SourceExtID -EntityExtID $EntityExtID
    Gets the current AIOps Timeline from the Prism Central Appliance with Source and Entity ExtID's.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-AIOpsTimeline.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$SourceExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$EntityExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {
        
        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($AiOpsNameSpace)/$($AIOpsApiVersion)/$($ModuleStats)/$($AIOpsResourceSources)/$($SourceExtID)/$($AIOpsResourceEntities)/$($EntityExtID)"
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
