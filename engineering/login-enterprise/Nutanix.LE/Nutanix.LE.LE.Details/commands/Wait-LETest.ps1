function Wait-LETest {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER testId
    Description of each parameter being passed into the function.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    What the function returns.

    .EXAMPLE
    PS> function-template -parameter "parameter detail"
    Description of the example.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/function-template.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.LE

#>
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)] 
        [AllowEmptyString()] 
        [string] $testId
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
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
            #Write-Log -Message ""
            Write-Log -Message "Test finished" -Level Info
        } 
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
