function Get-VMTemplates {

<#
    .SYNOPSIS
    Gets the VM Templates from Nutanix Prism Central.

    .DESCRIPTION
    This function will run an Api call against Prism Central and will return all the VM Templates currently registered.

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the query result and either the data from the query or the error message

    .EXAMPLE
    PS> Get-VMTemplates
    Gets the current VM Templates from Prism Central.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-VMTemplates.md

#>

    [CmdletBinding()]

    Param ()

    begin {

        # Set strict mode 
        Set-StrictMode -Version Latest

    } # begin

    process {
            
        # Build Base Api Reference
        $ApiPath = "/$($ApiRoot)/$($VmmNameSpace)/$($VmmApiVersion)/$($TemplateResourceRoot)/$($VmmResourceTemplates)"
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api path - $($ApiPath)"

        # Execute Api Call
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Executing Api query - $($ApiPath)"
        $Result = Invoke-NutanixApiCall -ApiPath $ApiPath

    } # process

    end {

        return Get-ReturnData -Result $Result -CmdLet $PSCmdlet.MyInvocation.MyCommand.Name

    } # end

}
