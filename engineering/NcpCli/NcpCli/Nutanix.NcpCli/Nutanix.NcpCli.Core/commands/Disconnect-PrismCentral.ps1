function Disconnect-PrismCentral {
<#
    .SYNOPSIS
    Executes an API call to disconnect from a Prism Central instance.

    .DESCRIPTION
    This function will run an Api call against Prism Central and disconnect the user session.

    .INPUTS
    None

    .OUTPUTS
    None

    .EXAMPLE
    PS> Disconnect-PrismCentral
    Disconnects from the Prism Central instance.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Nutanix/Disconnect-PrismCentral.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli

#>
    
    [CmdletBinding()]

    Param ()

    begin {} # begin

    process {

        # Kill the web session variable
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Disconnecting from Prism Central"
        Remove-Variable -Name ntnxSession -scope global
        
    } # process

    end {} # end

}