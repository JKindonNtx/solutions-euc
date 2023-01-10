function Get-LEtestrunResults {
    Param (
        [Parameter(Mandatory)] [string] $testRunId,
        $Path
    )
    
    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId"+"$path"
    $Response 
}