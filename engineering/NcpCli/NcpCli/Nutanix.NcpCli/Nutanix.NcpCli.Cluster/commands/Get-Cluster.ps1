function Get-Cluster {
<#
    .SYNOPSIS
    Returns the registered Clusters from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Clusters currently registered.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP.

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name.

    .PARAMETER PrismPassword
    Specifies the Prism Central Password.

    .PARAMETER ClusterExtID
    (Optional) Specifies the Ext ID (UUID) of the Cluster you want to return.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Nutanix Cluster information based on the parameters passed into the function.

    .EXAMPLE
    PS> Get-Cluster -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
    Gets the current Clusters from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-Cluster -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew"
    Gets the specific Ext ID Cluster from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-Cluster -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -Verbose
    Gets the specific Ext ID Cluster from the Prism Central Appliance with Verbose output.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-Cluster.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$ClusterExtID
    )

    begin{

        # Set strict mode 
        Set-StrictMode -Version Latest

    }

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ClusterApiRoot)/$($ClusterNameSpace)/$($ClusterApiVersion)/$($ClusterModuleConfig)/$($ClusterResourceClusters)"

        # If specific cluster is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $ClusterExtID)){
            $ApiPath = "$($ApiPath)/$($ClusterExtID)"
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
