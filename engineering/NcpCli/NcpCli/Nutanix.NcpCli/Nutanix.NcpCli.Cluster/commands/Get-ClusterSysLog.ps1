function Get-ClusterSysLog {

<#
    .SYNOPSIS
    Gets the Nutanix Cluster SysLog Information from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the Cluster SysLog Information.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER ClusterExtID
    Specifies the Ext ID (UUID) of the Cluster you want to return.

    .PARAMETER SysLogExtID
    Specifies the Ext ID (UUID) of the SysLog Server you want to return.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Nutanix Cluster SNMP information based on the parameters passed into the function.

    .EXAMPLE
    PS> Get-ClusterSysLog -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew"
    Gets the specific Ext ID Cluster SysLog Information from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-ClusterSysLog -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -SysLogExtID "4321fe1w-312ed-aee514325-feqwf"
    Gets the specific Ext ID Cluster SysLog Information for a specific SysLog Server from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-ClusterSysLog.md

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$ClusterExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$SysLogExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ClusterApiRoot)/$($ClusterNameSpace)/$($ClusterApiVersion)/$($ClusterModuleConfig)/$($ClusterResourceClusters)/$($ClusterExtID)/$($ClusterResourceSYSLOG)"

        # If specific cluster is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $SysLogExtID)){
            $ApiPath = "$($ApiPath)/$($SysLogExtID)"
        } 
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -PrismIP $PrismIP -PrismUserName $PrismUserName -PrismPassword $PrismPassword -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
