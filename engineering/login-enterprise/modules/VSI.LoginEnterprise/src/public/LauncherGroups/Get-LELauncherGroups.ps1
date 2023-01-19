function Get-LELauncherGroups {
    Param (
        [string]$orderBy = "Name",
        [string]$Direction = "asc",
        [string]$Count = "50",
        [string]$Include = "none"
    )

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/launcher-groups" -Body $Body
    $Response.items
}