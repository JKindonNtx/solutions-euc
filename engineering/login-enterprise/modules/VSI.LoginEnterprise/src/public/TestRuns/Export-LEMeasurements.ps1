function Export-LEMeasurements {
    param(
        $Folder,
        $TestRun,
        $DurationInMinutes
    )
    $v6apistring = "v6"
    try {
        $resp = Invoke-PublicApiMethod -Path "$v6apistring/docs/index.html" 
        $v6api = $false
    } catch {
        if ($_.Exception.Response.StatusCode -eq "NotFound") {
            $v6api = $false
        } else {
            throw $_
        }
    }
    if ($v6api) {
        $resp = Invoke-PublicApiMethod -Path "$v6apistring/test-runs/$($testRun.id)/export/create"
        while ((Invoke-PublicApiMethod -Path "$v6apistring/test-runs/$($testRun.id)/export/status") -ne "Completed") {
            Start-Sleep -Seconds 5
        }
        $zipFile = "$env:temp\LE_testRun_$($testRun.id).zip"
        Invoke-PublicApiMethod -method GET -Path "$v6apistring/test-runs/$($testRun.id)/export/content/csvzip" -OutFile $zipFile
        Expand-Archive -Path $zipFile -DestinationPath $Folder
    } else {
        $TestRun = Get-LETestRuns -testId $TestRun.testId | Select-Object -Last 1
        # User Sessions
        $UserSessions = Get-LEUserSessions -testRunId $TestRun.id
        $UserSessionsCollection = @()
        foreach ($UserSession in $UserSessions) {
            $Session = New-Object PSObject
            $Session | Add-Member -MemberType NoteProperty -Name "sessionId" -Value $UserSession.id
            $Session | Add-Member -MemberType NoteProperty -Name "launchOffsetInSeconds" -Value ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $UserSession.loginStartTime)).TotalSeconds)
            $Session | Add-Member -MemberType NoteProperty -Name "sessionStartOffsetInSeconds" -Value ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $UserSession.loginEndTime)).TotalSeconds)
            $Session | Add-Member -MemberType NoteProperty -Name "sessionEndOffsetInSeconds" -Value ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $UserSession.sessionEndTime)).TotalSeconds)
            $Session | Add-Member -MemberType NoteProperty -Name "sessionState" -Value $UserSession.sessionState
            if ($UserSession.loginState -eq "completed" -or $UserSession.sessionState -eq "succeeded") {
                $Session | Add-Member -MemberType NoteProperty -Name "loginState" -Value "TRUE"
            } else {
                $Session | Add-Member -MemberType NoteProperty -Name "loginState" -Value "FALSE"
            }
            if ($DurationInMinutes * 60 -lt $Session.sessionEndOffsetInSeconds) {
                $Session | Add-Member -MemberType NoteProperty -Name "sessionDidRunUntilEndOfTest" -Value "TRUE"
            } else { $Session | Add-Member -MemberType NoteProperty -Name "sessionDidRunUntilEndOfTest" -Value "FALSE" }
        
            $Session | Add-Member -MemberType NoteProperty -Name "properties" -Value ($UserSession.Properties | ConvertTo-Json)
            $Session | Add-Member -MemberType NoteProperty -Name "host" -Value ($UserSession.Properties | Where-Object { $_.propertyId -eq "TargetHost" } | Select-Object -expand value)
            $Session | Add-Member -MemberType NoteProperty -Name "os" -Value ($UserSession.Properties | Where-Object { $_.propertyId -eq "TargetOS" } | Select-Object -expand value)
            $Session | Add-Member -MemberType NoteProperty -Name "cpu" -Value ($UserSession.Properties | Where-Object { $_.propertyId -eq "CPU" } | Select-Object -expand value)
            $Session | Add-Member -MemberType NoteProperty -Name "cores" -Value ($UserSession.Properties | Where-Object { $_.propertyId -eq "Cores" } | Select-Object -expand value)
            $Session | Add-Member -MemberType NoteProperty -Name "display" -Value ($UserSession.Properties | Where-Object { $_.propertyId -eq "Resolution" } | Select-Object -expand value)
            $Session | Add-Member -MemberType NoteProperty -Name "protocol" -Value ($UserSession.Properties | Where-Object { $_.propertyId -eq "RemotingProtocol" } | Select-Object -expand value)
            $UserSessionsCollection += $Session
        }
        $UserSessionsCollection | Export-Csv -Path "$($Folder)\User Sessions.csv" -NoTypeInformation

        $SessionMeasurements = Get-LEMeasurements -testRunId $testRun.Id -include "sessionMeasurements"
        $LoginTimesCollection = @()
        foreach ($Measurement in $SessionMeasurements | Where-Object { $_.measurementId -eq "connection" -or $_.measurementId -eq "group_policies" -or $_.measurementId -eq "total_login_time" -or $_.measurementId -eq "user_profile" }) {
            $LoginTime = New-Object PSObject
            $LoginTime | Add-Member -MemberType NoteProperty -Name "id" -Value $Measurement.measurementId
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
        $AppMeasurements = $AppMeasurements | Select-Object measurementId, @{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } }, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
        $AppMeasurements | Export-Csv -Path "$($Folder)\Raw AppMeasurements.csv" -NoTypeInformation
   
        $AppExecutions = @()
        foreach ($UserSession in $UserSessions) {
            $ApplicationExecutions = Get-LEAppExecutions -testRunId $TestRun.Id -UserSessionId $UserSession.id
            #id,state, userSessionId, startOffset, endOffset, applicationName
            $ApplicationExecutions = $ApplicationExecutions | Select-Object id, state, userSessionId, @{Name = "startOffSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.created)).TotalSeconds) } }, @{Name = "endOffSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.lastModified)).TotalSeconds) } }, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
            $AppExecutions += $ApplicationExecutions
        }
        $AppExecutions | Export-Csv -Path "$($Folder)\Raw AppExecutions.csv" -NoTypeInformation

        $EUXMeasurements = $VSIresults = Get-LEtestrunResults -testRunId $testRun.Id -path "/eux-results"
        $EUXCollection = @()
        foreach ($Measurement in $EUXMeasurements) {
            $EUXscore = New-Object PSObject
            $EUXscore | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $Measurement.timestamp
            $EUXscore | Add-Member -MemberType NoteProperty -Name "EUXScore" -Value $Measurement.score
            $EUXCollection += $EUXscore
        }
        $EUXCollection | Export-Csv -Path "$($Folder)\EUX-score.csv" -NoTypeInformation

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
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax" -Value $result.vsiMax.maxSessions
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax version" -Value $result.vsiMax.version
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax state" -Value $result.vsiMax.state
            $VSIresult | Add-Member -MemberType NoteProperty -Name "Comment" -Value $result.comment
            $VSIresult | Add-Member -MemberType NoteProperty -Name "started" -Value $result.started
            $VSIresult | Add-Member -MemberType NoteProperty -Name "finished" -Value $result.finished
            $VSICollection += $VSIresult
        }
        $VSICollection | Export-Csv -Path "$($Folder)\VSI-results.csv" -NoTypeInformation


     
        <#
    NOT VALID FOR 4.8 anymore, not worth the effort
    $ResultsPerMinuteCollection = Measure-Statistics -Collection $TimerCollection -startOffset -4 -endOffSet 4
    #>
    }
}

function Measure-Statistics {
    param(
        $Collection,
        [Int32]$startOffset = -4,
        [Int32]$endOffSet = 4
    )
    $ReturnCollection = @()
    # Group the collection by minute
    $CollectionMinutes = $Collection | Select-Object id, result, sessionId, offsetInSeconds, @{Name = "minute"; Expression = { [Math]::Floor($_.offsetInSeconds / 60) } } | Group-Object -Property minute
    foreach ($Group in $CollectionMinutes) {
        [int]$CurrentMinute = $Group.Name
        # Get rolling average based on start and endoffset
        $Results = $CollectionMinutes | Where-Object { [Int32]$_.Name -gt ($CurrentMinute + $startOffset) -and [int]$_.Name -le ($CurrentMinute + $endOffSet) } | Select-Object -ExpandProperty Group
        $Counters = $Results | Group-Object -Property id
        $Counter = New-Object PSObject
        $Counter | Add-Member -MemberType NoteProperty -Name "Minute" -Value $CurrentMinute
        # Calculate Averages, Mean, Count, Worst10Pct per counter and add them to the collection
        foreach ($CounterGroup in $Counters) {
            $Counter | Add-Member -MemberType NoteProperty -Name "$($CounterGroup.Name)_Count" -Value $CounterGroup.Count
            $Counter | Add-Member -MemberType NoteProperty -Name "$($CounterGroup.Name)_Average" -Value $(($CounterGroup.Group | Measure-Object -Property result -Average).Average)
            $SortedValues = $CounterGroup.group | Select-Object -ExpandProperty result | Sort-Object
            if ($SortedValues.Count % 2 -eq 1) {
                # Odd number of values, divide count by 2 and round up
                $MeanIndex = [Math]::Ceiling(($SortedValues.Count / 2))
                $Mean = $SortedValues[$MeanIndex]
            } else {
                # Even number of value, divide count by 2 and get both floor and ceil
                $MeanIndex = $SortedValues.Count / 2
                $Mean = ($SortedValues[$MeanIndex] + $SortedValues[$MeanIndex + 1]) / 2
            }
            $Counter | Add-Member -MemberType NoteProperty -Name "$($CounterGroup.Name)_Mean" -Value $Mean
            # EUXBAND - [Floor]75-[Ceiling]90%

        }
        $ReturnCollection += $Counter
    }
    return $ReturnCollection
}