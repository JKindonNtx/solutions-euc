function Get-LELaunchers {

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
        Break
    }

}
