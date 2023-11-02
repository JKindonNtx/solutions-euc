function Get-Host {

<#
    .SYNOPSIS
    Gets the Hosts from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Hosts currently registered.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER ClusterExtID
    (Optional) Specifies the Ext ID (UUID) of the Cluster Hosts you want to return.

    .PARAMETER HostExtID
    (Optional) Specifies the Ext ID (UUID) of the Host you want to return.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Nutanix Host information based on either Prism Central, the Cluster or the Host passed in.

    .EXAMPLE
    PS> Get-Host -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password"
    Gets the current Hosts from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-Host -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew"
    Gets all the Hosts from the specific Cluster passed in from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-Host -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543"
    Gets the Host from the specific Cluster passed in from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-Host.md

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$ClusterExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$HostExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {   
            
        # Build Api Reference
        $BaseApiPath = "/$($ClusterApiRoot)/$($ClusterNameSpace)/$($ClusterApiVersion)/$($ClusterModuleConfig)"

        # All Hosts in Prism Central
        if(((Get-NullVariable -Check $ClusterExtID)) -and ((Get-NullVariable -Check $HostExtID))){
            $ApiPath = "$($BaseApiPath)/$($ClusterResourceHosts)"
        } 

        # Hosts on a specific cluster
        if((!(Get-NullVariable -Check $ClusterExtID)) -and ((Get-NullVariable -Check $HostExtID))){
            $ApiPath = "$($BaseApiPath)/$($ClusterResourceClusters)/$($ClusterExtID)/$($ClusterResourceHosts)"
        } 

        # Specific Host
        if((!(Get-NullVariable -Check $ClusterExtID)) -and (!(Get-NullVariable -Check $HostExtID))){
            $ApiPath = "$($BaseApiPath)/$($ClusterResourceClusters)/$($ClusterExtID)/$($ClusterResourceHosts)/$($HostExtID)"
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
