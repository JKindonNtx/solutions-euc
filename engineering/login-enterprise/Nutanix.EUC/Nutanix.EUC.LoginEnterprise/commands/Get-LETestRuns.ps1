function Get-LETestRuns {
    Param (
        [Parameter(Mandatory)] [string] $testId,
        [ValidateSet('asc', 'desc')] [string] $Direction = "asc",
        [string]$count = 10000,
        [Parameter()] [ValidateSet('none', 'properties', 'all')] [string] $include = "none"
    )

    $Body = @{
        direction = $direction
        count     = $Count
        include   = $Include
    }
    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/tests/$TestId/test-runs" -Body $Body
    $Response.items
}