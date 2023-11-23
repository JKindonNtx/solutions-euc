function Get-LEApplications {

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
        Break
    }
    $Response.items

}
