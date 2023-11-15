function Get-LEAccountGroups  {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER orderBy
    .PARAMETER Direction
    .PARAMETER Count
    .PARAMETER Include

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
        [Parameter(mandatory = $false)][string]$orderBy = "name",
        [Parameter(mandatory = $false)][string]$Direction = "asc",
        [Parameter(mandatory = $false)][Int32]$Count = 10000,
        [Parameter(mandatory = $false)][string]$Include = "none"
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting Get-LEAccountGroups" -Level Info
    }

    process {
        $Body = @{
            orderBy   = $orderBy
            direction = $Direction
            count     = $Count
            include   = $Include
        }

        try {
            $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/account-groups" -Body $Body -ErrorAction Stop
            $Response.items
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Get-LEAccountGroups" -Level Info
    } # end

}
