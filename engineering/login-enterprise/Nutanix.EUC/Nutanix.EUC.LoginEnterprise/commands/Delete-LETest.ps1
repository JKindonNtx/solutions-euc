function Delete-LETest {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][string] $testId,
        [Parameter(Mandatory = $false)][ValidateSet('none', 'environment', 'workload', 'thresholds', 'all')][string] $include = "all"
    )
    
    try {
        $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v7-preview/tests/$testId" -ErrorAction Stop
    }
    catch {
        Write-Log -Message "Failed to delete test" -Level Error
        Write-Log -Message $_ -Level Error
        Break
    }
    $Response

}
