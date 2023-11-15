function Get-LEAccounts {
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
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$orderBy = "Username",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Direction = "asc",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][int32]$Count = 10000,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Include = "none"
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting Get-LEAccounts" -Level Info
    }

    process {
        $Body = @{
            orderBy   = $orderBy
            direction = $Direction
            count     = $Count
            include   = $Include
        }
        try {
            $Response = Invoke-PublicApiMethod -Path 'v6/accounts' -Method 'GET' -Body $Body -ErrorAction Stop
            $Response.items
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Get-LEAccounts" -Level Info
    } # end

}
