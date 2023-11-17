function Get-LELauncherGroups {


    Param (
        $orderBy = "Name",
        $Direction = "asc",
        $Count = "50",
        $Include = "none"
    )

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include
    }
    
    try {
        $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/launcher-groups" -Body $Body -ErrorAction Stop
        $Response.items
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
        
}
