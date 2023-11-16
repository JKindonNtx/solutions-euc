function Get-LELaunchers {

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting Get-LELaunchers" -Level Info
    }

    process {
        $Body = @{
            orderBy   = "Name"
            direction = "Asc"
            count     = "5000"
        }
        try {
            $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/launchers" -Body $Body -ErrorAction Stop
            $Response.items
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing Get-LELaunchers" -Level Info
    } # end

}
