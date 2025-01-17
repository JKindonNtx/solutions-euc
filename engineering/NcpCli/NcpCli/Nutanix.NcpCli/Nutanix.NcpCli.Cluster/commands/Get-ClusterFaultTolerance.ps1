function Get-ClusterFaultTolerance {
<#
    .SYNOPSIS
    Gets the Cluster Fault Tolerance level from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the Cluster Fault Tolerance level for the passed in cluster.

    .PARAMETER ClusterExtID
    Specifies the Ext ID (UUID) of the Cluster you want to return.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Nutanix Cluster Fault Tollerance information based on the parameters passed into the function.

    .EXAMPLE
    PS> Get-ClusterFaultTolerance -ClusterExtID "432re2de21-d1323d21-ewqER312QE3R-DFEQWFEDW"
    Gets the Cluster with Ext ID "432re2de21-d1323d21-ewqER312QE3R-DFEQWFEDW" Fault Tolerance level from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterFaultTolerance.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$ClusterExtID
    )

    begin{

        # Set strict mode 
        Set-StrictMode -Version Latest

    }

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($ClusterNameSpace)/$($ClusterApiVersion)/$($ModuleConfig)/$($ClusterResourceClusters)/$($ClusterExtID)/$($ClusterResourceFaultToleranceStatus)"
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
