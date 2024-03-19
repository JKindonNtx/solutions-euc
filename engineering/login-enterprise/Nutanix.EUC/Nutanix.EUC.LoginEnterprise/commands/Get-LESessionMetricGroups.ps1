function Get-LESessionMetricGroups {
    # https://ws-le3.wsperf.nutanix.com/publicApi/v7-preview/docs/index.html#operation/Data_GetUserSessionMetricGroups
    param (
        [ValidateSet('asc', 'desc')] [string] $Direction = "asc",
        [string]$count = 10000,
        [Parameter()] [ValidateSet('name', 'memberCount')] [string] $orderBy = "timestamp",
        [int]$OffSet = 0,
        [bool]$includeTotalCount
    )

    $Body = @{
        direction         = $direction
        count             = $Count
        includeTotalCount = $includeTotalCount 
        offset            = $OffSet
        orderBy           = "name"
    } 

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v7-preview/session-metric-definition-groups" -Body $Body
    $Response.items     
}