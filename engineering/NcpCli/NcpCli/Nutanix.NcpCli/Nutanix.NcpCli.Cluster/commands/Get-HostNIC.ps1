function Get-HostNIC {

<#
    .SYNOPSIS
    Gets the Host NICS from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the Host NICS currently registered.
    
    .PARAMETER PrismIP
    Specifies the Prism Central IP

    .PARAMETER PrismUserName
    Specifies the Prism Central User Name

    .PARAMETER PrismPassword
    Specifies the Prism Central Password

    .PARAMETER ClusterExtID
    Specifies the Ext ID (UUID) of the Cluster you want to return.

    .PARAMETER HostExtID
    Specifies the Ext ID (UUID) of the Host you want to return.

    .PARAMETER HostNICExtID
    Specifies the Ext ID (UUID) of the Host NIC you want to return.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the Nutanix Host NIC information based on either the Host passed in or the individual NIC.

    .EXAMPLE
    PS> Get-HostNIC -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543"
    Gets the Host NICs from the specific Cluster passed in from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-HostNIC -PrismIP "10.10.10.10" -PrismUserName "admin" -PrismPassword "password" -ClusterExtID "fds3r43-432qqr-w342fewfew" -HostExtID "fdfrwf3-fews43rw2-453253245432543" -HostNICExtID "34225234-431321414-341324-3414"
    Gets the Specific Host NIC from the specific Cluster passed in from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-HostNIC.md

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismIP,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$PrismPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$ClusterExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$HostExtID,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$HostNICExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Api Reference
        $ApiPath = "/$($ClusterApiRoot)/$($ClusterNameSpace)/$($ClusterApiVersion)/$($ClusterModuleConfig)/$($ClusterResourceClusters)/$($ClusterExtID)/$($ClusterResourceHosts)/$($HostExtID)/$($ClusterResourceHostNIC)"
        
        # If specific NIC is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $HostNICExtID)){
            $ApiPath = "$($ApiPath)/$($HostNICExtID)"
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
