function Get-LEEUXscore {
    Param (
        [Parameter(Mandatory)] [string] $testRunId
    )

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId/eux-results"
    $Response 
}