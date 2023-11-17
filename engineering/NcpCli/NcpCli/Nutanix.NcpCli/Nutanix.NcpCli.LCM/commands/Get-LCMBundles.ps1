function Get-LCMBundles {
<#
    .SYNOPSIS
    Gets the LCM Bundles from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the LCM Bundles available.

    .PARAMETER BundleExtID
    (Optional) Specifies the UUID of the Bundle you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the available LCM bundles or a specific one depending on the parameters passed in.

    .EXAMPLE
    PS> Get-LCMBundles
    Gets the current Bindles from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-LCMBundles -BundleExtID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Bundle from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-LCMBundles.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$BundleExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($LCMNameSpace)/$($LCMApiVersion)/$($ModuleResources)/$($LCMResourceBundles)"

        # If specific value is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $BundleExtID)){
            $ApiPath = "$($ApiPath)/$($BundleExtID)"
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
