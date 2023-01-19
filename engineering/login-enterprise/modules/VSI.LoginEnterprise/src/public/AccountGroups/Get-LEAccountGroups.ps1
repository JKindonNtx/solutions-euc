function Get-LEAccountGroups {
    Param (
        [string]$orderBy = "name",
        [string]$Direction = "asc",
        [Int32]$Count = 10000,
        [string]$Include = "none"
    )

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/account-groups" -Body $Body
    $Response.items
}
