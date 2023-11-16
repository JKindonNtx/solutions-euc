function Get-LERawEUX {
    Param (
        [Parameter(Mandatory)] [string] $testRunId,
        [Parameter(Mandatory = $false)][string]$count = 100000
    )

    $Body = @{
        count = $Count
    } 

    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/test-runs/$TestRunId/eux-script-executions" -Body $Body
    $Response.items 
}