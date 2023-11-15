function Remove-LEAccounts {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER ids
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
        [Parameter(Mandatory = $true)][array]$ids
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting Remove-LEAccounts" -Level Info
    }

    process {
        $Body = ConvertTo-Json @($ids)

        try {
            $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v6/accounts" -Body $Body -ErrorAction Stop
            $Response.id
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }

    
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Remove-LEAccounts" -Level Info
    } # end

}
