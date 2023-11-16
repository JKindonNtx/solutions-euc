function Get-LEAccounts {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$orderBy = "Username",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Direction = "asc",
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][int32]$Count = 10000,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][string]$Include = "none"
    )

    begin {
        # Set strict mode 
        # Set-StrictMode -Version Latest
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
            Break
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Get-LEAccounts" -Level Info
        return $Response.items
    } # end

}
