function Get-LETest {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][string] $testId,
        [Parameter(Mandatory = $false)][ValidateSet('none', 'environment', 'workload', 'thresholds', 'all')][string] $include = "all"
    )

    $Body = @{
        include = $include
    }
    
    try {
        $Response = Invoke-PublicApiMethod -Method "GET" -Path "v6/tests/$testId" -Body $Body -ErrorAction Stop
    }
    catch {
        Write-Log -Message "Failed to retrieve test info" -Level Error
        Write-Log -Message $_ -Level Error
        Break
    }
    $Response

}
