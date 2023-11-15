function Connect-LEAppliance {
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
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.LE

#>
    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.String]$URL,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.String]$Token
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        $global:LE_URL = $url.TrimEnd("/")
        $global:LE_Token = $token

        if ($null -eq (Get-LEApplications)) {
            Write-Log -Message "Failed to connect to appliance at $url, please check that the URL and Token are correct" -Level Error
            Exit 1
        }
        else {
            Write-Log -Message "Connected to VSI Appliance at URL: $($global:LE_URL)" -Level Info
        }
    } # process

    end {
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
