function Get-LETests {
    Param (
        [ValidateSet('name', 'connector', 'description')] [string] $orderBy = "name",
        [ValidateSet('continuousTest', 'loadTest', 'applicationTest')] [string] $testType = "loadTest",
        [ValidateSet('asc', 'desc')] [string] $Direction = "asc",
        [ValidateSet('environment', 'workload', 'thresholds', 'all', 'none')] [string] $include = "none",
        [string]$count = 10000
    )

    $Body = @{
        testType  = $testType
        orderBy   = $orderBy
        direction = $direction
        count     = $Count
        include   = $Include
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/tests" -Body $Body
    $Response.items
}