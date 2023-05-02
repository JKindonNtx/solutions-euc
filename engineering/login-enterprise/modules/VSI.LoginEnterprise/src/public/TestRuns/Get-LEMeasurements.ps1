function Get-LEMeasurements {
    Param (
        [Parameter(Mandatory)] [string] $testRunId,
        [string] $from = $null,
        [string] $to = $null,
        [ValidateSet('asc', 'desc')] [string] $Direction = "asc",
        [string]$count = 10000,
        [Parameter()] [ValidateSet('sessionMeasurements', 'applicationMeasurements', 'all')] [string] $include = "all",
        [int]$OffSet = 0
    )

    $Body = @{
        direction = $direction
        from      = $from
        to        = $to
        count     = $Count
        include   = $Include 
        offset    = $OffSet
    } 

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId/measurements" -Body $Body
    $Response.items 
}