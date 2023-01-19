function Get-LELauncherGroupMembers {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        [string]$orderBy = "Name",
        [string]$Direction = "asc",
        [string]$Count = "50",
        [string]$Include = "none"
    )
    $Body = @{
        groupID   = $GroupId
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
        include   = $Include
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/launcher-groups/$GroupId/members" -Body $Body
    $Response.items
}