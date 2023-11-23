function Get-LEAppExecutions {
    Param (
        [Parameter(Mandatory)] [string] $testRunId,
        [Parameter(Mandatory)] [string] $UserSessionId,
        [string] $from = $null,
        [string] $to = $null,
        [ValidateSet('asc', 'desc')] [string] $Direction = "asc",
        [string]$count = 10000,
        [boolean] $includeTotal = $false
    )

    $Body = @{
        direction         = $direction
        from              = $from
        to                = $to
        count             = $Count
        includeTotalCount = $includeTotal
    } 

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId/user-sessions/$UserSessionId/app-executions" -Body $Body
    $Response.items 
}