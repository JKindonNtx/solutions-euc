function Wait-LETest {
    Param (
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $testId
    )
    if (-not ([string]::IsNullOrEmpty($testId))) {
    
        Write-Log "Waiting for test to complete"
        $test = (Get-LETest -testId $testid -include "none")
        $state = $test.state
        while (($state -eq "running") -or ($state -eq "stopping")) {
            Start-Sleep -Seconds 1
            Write-Log -Update "Test state: $($TestRun.State), $($TestRun.loginCounts.successCount)/$($TestRun.loginCounts.totalCount) logins"
            $TestRun = Get-LETestRuns -testId $testId | Select-Object -Last 1
            $CurrentDate = (Get-Date).ToUniversalTime()
            If ($null -ne $TestRun.Started) {
                $Timespan = New-TimeSpan (get-date $TestRun.Started) $CurrentDate
            }
            Write-Log -Update "Test state: $($TestRun.State), $([Math]::Round($TimeSpan.TotalMinutes,0)) of $($test.rampupDurationInMinutes + $test.testDurationInMinutes + $test.rampDownDurationInMinutes ) estimated minutes elapsed, $($TestRun.loginCounts.successCount)/$($TestRun.loginCounts.totalCount) logins, $($TestRun.engineCounts.successCount)/$($TestRun.engineCounts.totalCount) engines, $($TestRun.appExecutionCounts.successCount)/$($TestRun.appExecutionCounts.totalCount) applications"
            $state = (Get-LETest -testId $testid -include "none").state
        }
        Write-Log ""
        Write-Log "Test finished"
    } 
}