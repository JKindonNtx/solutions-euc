function function-template {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER ParameterName
    Description of each parameter being passed into the function.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    What the function returns.

    .EXAMPLE
    PS> function-template -parameter "parameter detail"
    Description of the example.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/function-template.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.EUC

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.String]$ParameterName
    )

    begin {
        # Set strict mode 
        # Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        # Process code for the function
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
