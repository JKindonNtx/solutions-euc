function Get-LETests {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $false)][ValidateSet('name', 'connector', 'description')][string]$orderBy = "name",
        [Parameter(Mandatory = $false)][ValidateSet('continuousTest', 'loadTest', 'applicationTest')][string] $testType = "loadTest",
        [Parameter(Mandatory = $false)][ValidateSet('asc', 'desc')][string]$Direction = "asc",
        [Parameter(Mandatory = $false)][ValidateSet('environment', 'workload', 'thresholds', 'all', 'none')][string]$include = "none",
        [Parameter(Mandatory = $false)][string]$count = 10000
    )

    $Body = @{
        testType  = $testType
        orderBy   = $orderBy
        direction = $direction
        count     = $Count
        include   = $Include
    }
        
    $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/tests" -Body $Body
    $Response.items

}
