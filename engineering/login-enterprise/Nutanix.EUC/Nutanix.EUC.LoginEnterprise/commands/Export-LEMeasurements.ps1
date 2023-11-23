function Export-LEMeasurements {
    param(
        $Folder,
        $TestRun,
        $DurationInMinutes
    )

        $TestRun = Get-LETestRuns -testId $TestRun.testId | Select-Object -Last 1
        
        $SessionMeasurements = Get-LEMeasurements -testRunId $testRun.Id -include "sessionMeasurements"
        $LoginTimesCollection = @()
        foreach ($Measurement in $SessionMeasurements | Where-Object { $_.measurementId -eq "connection" -or $_.measurementId -eq "group_policies" -or $_.measurementId -eq "total_login_time" -or $_.measurementId -eq "user_profile" }) {
            $LoginTime = New-Object PSObject
            $LoginTime | Add-Member -MemberType NoteProperty -Name "id" -Value $Measurement.measurementId
            $LoginTime | Add-Member -MemberType NoteProperty -Name "timestamp" -Value $Measurement.timestamp
            $LoginTime | Add-Member -MemberType NoteProperty -Name "offsetInSeconds" -Value ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $Measurement.timestamp)).TotalSeconds)
            $LoginTime | Add-Member -MemberType NoteProperty -Name "result" -Value ($Measurement.duration / 1000)
            $LoginTime | Add-Member -MemberType NoteProperty -Name "sessionId" -Value $Measurement.userSessionId
            $LoginTimesCollection += $LoginTime
        }
        $LoginTimesCollection | Export-Csv -Path "$($Folder)\Raw Login Times.csv" -NoTypeInformation

        $EUXMeasurements = Get-LERawEUX -testRunId $testRun.Id
        $TimerCollection = @()
        foreach ($Measurement in $EUXMeasurements) {
            $EuxUser = $Measurement.euxMeasurements
            foreach ($EuxMeasurement in $EuxUser) {
                $Timer = New-Object PSObject
                $Timer | Add-Member -MemberType NoteProperty -Name "userSessionid" -Value $Measurement.UserSessionId
                $Timer | Add-Member -MemberType NoteProperty -Name "timestamp" -Value $EuxMeasurement.timestamp
                $Timer | Add-Member -MemberType NoteProperty -Name "timer" -Value $EuxMeasurement.timer
                $Timer | Add-Member -MemberType NoteProperty -Name "duration" -Value $EuxMeasurement.duration
                $TimerCollection += $Timer
            }
        }
        $TimerCollection | Export-Csv -Path "$($Folder)\Raw Timer Results.csv" -NoTypeInformation
    
        #lookup table
        $Applications = Get-LEApplications

        $AppMeasurements = Get-LEMeasurements -testRunId $testRun.Id -include "applicationMeasurements"
        #id, offsetInSeconds, result, userSessionId, appexecutionId, applicationName
        $AppMeasurements = $AppMeasurements | Select-Object measurementId, timestamp, @{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } }, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
        
        if($AppMeasurements.count -eq 10000){
            $FileEnded = $false
            while(-not $FileEnded){
                [int]$OffSet = $AppMeasurements.count + 1
                $AppMeasurementsAdditional = Get-LEMeasurements -testRunId $testRun.Id -include "applicationMeasurements" -OffSet $OffSet
                $AppMeasurementsAdditional = $AppMeasurementsAdditional | Select-Object measurementId, timestamp, @{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } }, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
                $AppMeasurements = $AppMeasurements + $AppMeasurementsAdditional
                if($AppMeasurementsAdditional.count -lt 10000){
                    $FileEnded = $true
                } 
            }
        }
        $AppMeasurements | Export-Csv -Path "$($Folder)\Raw AppMeasurements.csv" -NoTypeInformation

        $EUXMeasurements = Get-LEtestrunResults -testRunId $testRun.Id -path "/eux-results"
        $EUXCollection = @()
        foreach ($Measurement in $EUXMeasurements) {
            $EUXscore = New-Object PSObject
            $EUXscore | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $Measurement.timestamp
            $EUXscore | Add-Member -MemberType NoteProperty -Name "EUXScore" -Value $Measurement.score
            $EUXCollection += $EUXscore
        }
        $EUXCollection | Export-Csv -Path "$($Folder)\EUX-score.csv" -NoTypeInformation

        ## EUX timer results
        $EUXtimerMeasurements = Get-LEtestrunResults -testRunId $testRun.Id -path "/eux-timer-results?euxTimer=diskMyDocs&euxTimer=diskMyDocsLatency&euxTimer=diskAppData&euxTimer=diskAppDataLatency&euxTimer=cpuSpeed&euxTimer=highCompression&euxTimer=fastCompression&euxTimer=appSpeed&euxTimer=appSpeedUserInput"
        $EUXtimerCollection = @()
        foreach ($timerMeasurement in $EUXtimerMeasurements) {
            $EUXtimerscore = New-Object PSObject
            $EUXtimerscore | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $timerMeasurement.timestamp
            $EUXtimerscore | Add-Member -MemberType NoteProperty -Name "EUXTimer" -Value $timerMeasurement.euxTimer
            $EUXtimerscore | Add-Member -MemberType NoteProperty -Name "Score" -Value $timerMeasurement.score
            $EUXtimerCollection += $EUXtimerscore
        }
        $EUXtimerCollection | Export-Csv -Path "$($Folder)\EUX-timer-score.csv" -NoTypeInformation

        

        $VSIresults = Get-LEtestrunResults -testRunId $testRun.Id
        $VSICollection = @()
        foreach ($result in $VSIresults) {
            $VSIresult = New-Object PSObject
            $VSIresult | Add-Member -MemberType NoteProperty -Name "type" -Value $result.type
            $VSIresult | Add-Member -MemberType NoteProperty -Name "state" -Value $result.state
            $VSIresult | Add-Member -MemberType NoteProperty -Name "activesessionCount" -Value $result.activeSessionCount
            $VSIresult | Add-Member -MemberType NoteProperty -Name "productVersion" -Value $result.productVersion
            $VSIresult | Add-Member -MemberType NoteProperty -Name "login success" -Value $result.loginCounts.successCount
            $VSIresult | Add-Member -MemberType NoteProperty -Name "login total" -Value $result.loginCounts.totalCount
            $VSIresult | Add-Member -MemberType NoteProperty -Name "login engine success" -Value $result.engineCounts.successCount
            $VSIresult | Add-Member -MemberType NoteProperty -Name "login engine total" -Value $result.engineCounts.totalCount
            $VSIresult | Add-Member -MemberType NoteProperty -Name "Apps success" -Value $result.appExecutionCounts.successCount
            $VSIresult | Add-Member -MemberType NoteProperty -Name "Apps total" -Value $result.appExecutionCounts.totalCount
            $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX score" -Value $result.euxScore.score
            $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX version" -Value $result.euxScore.version
            $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX state" -Value $result.euxScore.state
            if ($result.vsiMax.maxSessions -eq "") {
                $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax" -Value $result.loginCounts.totalCount
            } Else {
                $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax" -Value $result.vsiMax.maxSessions
            }
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax version" -Value $result.vsiMax.version
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax state" -Value $result.vsiMax.state
            $VSIresult | Add-Member -MemberType NoteProperty -Name "Comment" -Value $result.comment
            $VSIresult | Add-Member -MemberType NoteProperty -Name "started" -Value $result.started
            $VSIresult | Add-Member -MemberType NoteProperty -Name "finished" -Value $result.finished
            $VSICollection += $VSIresult
        }
        $VSICollection | Export-Csv -Path "$($Folder)\VSI-results.csv" -NoTypeInformation


     

    
}