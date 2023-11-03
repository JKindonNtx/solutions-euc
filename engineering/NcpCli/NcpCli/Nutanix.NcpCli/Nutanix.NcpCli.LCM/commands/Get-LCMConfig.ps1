function Get-LCMConfig {
<#
    .SYNOPSIS
    Gets the LCM Config from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return the LCM Config available.

    .INPUTS
    None.

    .OUTPUTS
    Returns the LCM configuration from Prism Central

    .EXAMPLE
    PS> Get-LCMConfig 
    Gets the current LCM Config from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-LCMConfig.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param ()

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($LCMNameSpace)/$($LCMApiVersion)/$($ModuleResources)/$($LCMResourceConfig)"
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
