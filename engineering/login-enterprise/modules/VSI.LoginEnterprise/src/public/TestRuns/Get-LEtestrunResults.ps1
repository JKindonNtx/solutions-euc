function Get-LEtestrunResults {
    Param (
        [Parameter(Mandatory)] [string] $testRunId,
        [AllowEmptyString()] [string] $Path
    )
    if (-not ([string]::IsNullOrEmpty($Path))) {
        $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId$Path"
    } Else {
        $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId"
    }
    $Response 
}