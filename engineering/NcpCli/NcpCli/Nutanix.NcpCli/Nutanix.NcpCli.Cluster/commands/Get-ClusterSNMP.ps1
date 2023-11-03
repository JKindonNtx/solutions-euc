function Get-ClusterSNMP {

<#
    .SYNOPSIS
    Gets the Cluster SNMP information from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the Cluster SNMP information.

    .PARAMETER ClusterExtID
    Specifies the Ext ID (UUID) of the Cluster you want to return.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Nutanix Cluster SNMP information based on the parameters passed into the function.

    .EXAMPLE
    PS> Get-ClusterSNMP -ClusterExtID "fds3r43-432qqr-w342fewfew"
    Gets the specific Ext ID Cluster SNMP Information from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterSNMP.md

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$ClusterExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($ClusterNameSpace)/$($ClusterApiVersion)/$($ModuleConfig)/$($ClusterResourceClusters)/$($ClusterExtID)/$($ClusterResourceSNMP)"
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}

