function Get-LCMHistory {
<#
    .SYNOPSIS
    Gets the LCM History from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the LCM History available.

    .PARAMETER HistoryExtID
    (Optional) Specifies the UUID of the History Item you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the LCM history data from Prism Central.

    .EXAMPLE
    PS> Get-LCMHistory 
    Gets the current History from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-LCMHistory -HistoryExtID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 History Item from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-LCMHistory.md
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$HistoryExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($LCMNameSpace)/$($LCMApiVersion)/$($ModuleResources)/$($LCMResourceHistory)"

        # If specific value is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $HistoryExtID)){
            $ApiPath = "$($ApiPath)/$($HistoryExtID)"
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
