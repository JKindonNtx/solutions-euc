function Get-LETest {
    Param (
        [Parameter(Mandatory)] [string] $testId,
        [ValidateSet('none', 'environment', 'workload', 'thresholds', 'all')] [string] $include = "all"
    )
    $Body = @{
        include = $include
    }

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/tests/$testId" -Body $Body
    $Response
}