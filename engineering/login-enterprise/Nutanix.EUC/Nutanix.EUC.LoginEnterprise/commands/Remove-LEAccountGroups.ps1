function Remove-LEAccountGroups {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][array]$ids
    )

    begin {
        # Set strict mode 
        # Set-StrictMode -Version Latest
        Write-Log -Message "Starting Remove-LEAccountGroups" -Level Info
    }

    process {
        
        $Body = ConvertTo-Json @($ids)

        try {
            Invoke-PublicApiMethod -Method "DELETE" -Path "v6/account-groups" -Body $Body -ErrorAction Stop

        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Remove-LEAccountGroups" -Level Info
    } # end

}
