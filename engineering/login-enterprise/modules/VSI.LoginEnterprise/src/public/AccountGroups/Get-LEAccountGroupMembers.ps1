function Get-LeAccountGroupMembers {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$GroupId,
        [string]$orderBy = "Username",
        [string]$Direction = "asc",
        [string]$Count = "50"
    )

    $Body = @{
        groupID   = $GroupId
        orderBy   = $orderBy
        direction = $Direction
        count     = $Count
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/account-groups/$GroupId/members" -Body $Body
    $Response.items
}