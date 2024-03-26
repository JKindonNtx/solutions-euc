function Get-LESessionDetails {
    #https://ws-le3.wsperf.nutanix.com/publicApi/v7-preview/test-runs/{testRunId}/user-sessions/{userSessionId}
    param (
        [Parameter(Mandatory)] [string] $testRunId,
        [Parameter(Mandatory)] [string] $userSessionId,
        [Parameter()] [ValidateSet('None', 'properties', 'all')] [string] $include = "all"
    )

    $Body = @{
        include          = $Include
    } 

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v7-preview/test-runs/$TestRunId/user-sessions/$userSessionId" -Body $Body
    
    $Response  
}