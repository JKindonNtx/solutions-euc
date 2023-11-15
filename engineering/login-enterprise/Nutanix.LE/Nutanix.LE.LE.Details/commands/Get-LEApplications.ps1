function Get-LEApplications {

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        #Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
        Write-Log -Message "Starting Get-LEApplications" -Level Info
    }

    process {
        $Body = @{
            orderBy   = "name"
            direction = "asc"
            count     = 10000
            include   = "none"
        }

        try {
            $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/applications" -Body $Body -ErrorAction Stop
        }
        catch {
            Write-Log -Message $_ -Level Error
            Exit 1
        }
        $Response.items
    } # process

    end {
        #Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
        Write-Log -Message "Finishing Get-LEApplications" -Level Info
    } # end

}
