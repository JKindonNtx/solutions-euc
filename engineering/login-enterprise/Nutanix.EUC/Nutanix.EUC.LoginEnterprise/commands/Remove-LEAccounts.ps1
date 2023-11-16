function Remove-LEAccounts {

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
