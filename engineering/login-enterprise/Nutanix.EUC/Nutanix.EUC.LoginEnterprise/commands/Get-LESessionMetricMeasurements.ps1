function Get-LESessionMetricMeasurements {
    # https://ws-le3.wsperf.nutanix.com/publicApi/v7-preview/docs/index.html#operation/Data_GetUserSessionMetrics
    param (
        [Parameter(Mandatory)] [string] $testRunId,
        [string] $from = $null,
        [string] $to = $null,
        [ValidateSet('asc', 'desc')] [string] $Direction = "asc",
        [string]$count = 10000,
        [Parameter()] [ValidateSet('displayName', 'timestamp')] [string] $orderBy = "timestamp",
        [int]$OffSet = 0,
        [bool]$includeTotalCount
    )

    $Body = @{
        direction         = $direction
        from              = $from
        to                = $to
        count             = $Count
        #include          = $Include
        includeTotalCount = $includeTotalCount 
        offset            = $OffSet
        orderBy           = "displayName"
    } 

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v7-preview/user-session-metrics/$TestRunId" -Body $Body
    $Response.items     
}