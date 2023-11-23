function Wait-LETest {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][AllowEmptyString()][string] $testId,
        $Waitparams
    )

    if (-not ([string]::IsNullOrEmpty($testId))) {
    
        Write-Log -Message "Waiting for test to complete" -Level Info
        $test = (Get-LETest -testId $testid -include "none")
        $state = $test.state
        while (($state -eq "running") -or ($state -eq "stopping")) {
            Start-Sleep -Seconds 5
            $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
            #$CurrentDate = (Get-Date).ToUniversalTime()
            $CurrentDate = Get-Date
            If ($null -ne $TestRun.Started) {
                $Timespan = New-TimeSpan (get-date $TestRun.Started) $CurrentDate
            }
            Write-Log -Update -Message "Test state: $($TestRun.State), $([Math]::Round($TimeSpan.TotalMinutes,0)) of $($test.rampupDurationInMinutes + $test.testDurationInMinutes + $test.rampDownDurationInMinutes ) estimated minutes elapsed, $($TestRun.loginCounts.successCount)/$($TestRun.loginCounts.totalCount) logins, $($TestRun.engineCounts.successCount)/$($TestRun.engineCounts.totalCount) engines, $($TestRun.appExecutionCounts.successCount)/$($TestRun.appExecutionCounts.totalCount) applications"
            $state = (Get-LETest -testId $testid -include "none").state
        }
        Write-Log -Message " " -Level Info
        Write-Log -Message "Test finished" -Level Info
    } 
}
