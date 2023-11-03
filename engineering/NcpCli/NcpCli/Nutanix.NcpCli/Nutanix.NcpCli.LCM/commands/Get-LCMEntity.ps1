function Get-LCMEntity {
<#
    .SYNOPSIS
    Gets the LCM Entities from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the LCM Entities available.

    .PARAMETER EntityExtID
    (Optional) Specifies the UUID of the Entity you wish to return

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    Returns the LCM entities or a specific entity based on the variablces passed into the function.

    .EXAMPLE
    PS> Get-LCMEntity
    Gets the current Entities from the Prism Central Appliance.

    .EXAMPLE
    PS> Get-LCMEntity -EntityExtID "78a1e6e7-5900-4f2a-839e-3b993e364889"
    Gets the 78a1e6e7-5900-4f2a-839e-3b993e364889 Entity from the Prism Central Appliance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-LCMEntity.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$false)][System.String]$EntityExtID
    )

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($LCMNameSpace)/$($LCMApiVersion)/$($ModuleResources)/$($LCMResourceEntity)"

        # If specific value is passed in then append that to the Api Uri
        if(!(Get-NullVariable -Check $EntityExtID)){
            $ApiPath = "$($ApiPath)/$($EntityExtID)"
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
