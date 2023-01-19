function Get-LEAccounts {
    Param (
        [string]$orderBy = "Username",
        [string]$Direction = "asc",
        [int32]$Count = 10000,
        [string]$Include = "none"
    )

    $Body = @{
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include
    }
    $Response = Invoke-PublicApiMethod -Path 'v6/accounts' -Method 'GET' -Body $Body
    $Response.items

}