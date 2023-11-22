function Get-LEUserSessions {
    Param (
        [Parameter(Mandatory)] [string] $testRunId,
        [string] $from = $null,
        [string] $to = $null,
        [ValidateSet('asc', 'desc')] [string] $Direction = "asc",
        [string]$count = 10000,
        [Parameter()] [ValidateSet('sessionMeasurements', 'applicationMeasurements', 'all')] [string] $include = "all"
    )

    $Body = @{
        direction = $direction
        from      = $from
        to        = $to
        count     = $Count
        include   = $Include 
    } 

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId/user-sessions" -Body $Body
    $Response.items 
}