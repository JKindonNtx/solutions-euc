function Get-HostVirtualNIC {

<#
    .SYNOPSIS
    Gets the Host Virtual NICS from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Host Virtual NICS currently registered.

    .PARAMETER ClusterExtID
    Specifies the Ext ID (UUID) of the Cluster you want to return.

    .PARAMETER HostExtID
    Specifies the Ext ID (UUID) of the Host you want to return.

    .PARAMETER HostVirtualNICExtID
    Specifies the Ext ID (UUID) of the Host Virtual NIC you want to return.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Nutanix Host Virtual NIC information based on either the Host passed in or the individual Virtual NIC.

    .EXAMPLE
    PS> Get-HostVirtualNIC -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543"
    Gets the Host Virtual NICs from the specific Cluster passed in from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-HostVirtualNIC -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543" -HostVirtualNICExtID "34225234-431321414-341324-3414"
    Gets the Host Virtual NICs from the specific Cluster passed in from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-HostVirtualNIC.md

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$ClusterExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$HostExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$HostVirtualNICExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Api Reference
        $ApiPath = "/$($ApiRoot)/$($ClusterNameSpace)/$($ClusterApiVersion)/$($ModuleConfig)/$($ClusterResourceClusters)/$($ClusterExtID)/$($ClusterResourceHosts)/$($HostExtID)/$($ClusterResourceHostVirtualNIC)"
        
        # If specific NIC is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $HostVirtualNICExtID)){
            $ApiPath = "$($ApiPath)/$($HostVirtualNICExtID)"
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
