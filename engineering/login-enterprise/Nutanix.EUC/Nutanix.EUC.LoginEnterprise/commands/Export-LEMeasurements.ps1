function Export-LEMeasurements {
    param(
        [Parameter(Mandatory = $true)][string]$Folder,
        [Parameter(Mandatory = $true)]$TestRun,
        [Parameter(Mandatory = $true)][string]$DurationInMinutes,
        [Parameter(Mandatory = $false)]$SessionMetricsEnabled
    )

    # Get the LE Test Run Details
    $TestRun = Get-LETestRuns -testId $TestRun.testId | Select-Object -Last 1

    #region Session Measurements and Logon Times

    Write-Log -Message "[DATA EXPORT] Processing Login Enterprise Session Metrics and login data" -Level Info

    Write-Log -Message "[DATA EXPORT] Pulling Login Enterprise Session Measurements metrics" -Level Info

    # start a timer for gathering session metrics
    $SessionMeasurementsGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

    $SessionMeasurements = Get-LEMeasurements -testRunId $testRun.Id -include "sessionMeasurements"
    # stop the timer for gathering session metrics
    $SessionMeasurementsGatheringStopWatch.stop()
    $ElapsedTime = [math]::Round($SessionMeasurementsGatheringStopWatch.Elapsed.TotalSeconds, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull $($SessionMeasurements.Count) metrics from Login Enterprise" -Level Info

    # Create the LoginTimesCollection Array List
    $LoginTimesCollection = [System.Collections.ArrayList] @()

    foreach ($Measurement in $SessionMeasurements | Where-Object { $_.measurementId -eq "connection" -or $_.measurementId -eq "group_policies" -or $_.measurementId -eq "total_login_time" -or $_.measurementId -eq "user_profile" }) {
        $LoginTime = New-Object PSObject
        $LoginTime | Add-Member -MemberType NoteProperty -Name "id" -Value $Measurement.measurementId
        $LoginTime | Add-Member -MemberType NoteProperty -Name "timestamp" -Value $Measurement.timestamp
        #$LoginTime | Add-Member -MemberType NoteProperty -Name "offsetInSeconds" -Value ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $Measurement.timestamp)).TotalSeconds)
        $LoginTime | Add-Member -MemberType NoteProperty -Name "result" -Value ($Measurement.duration / 1000)
        $LoginTime | Add-Member -MemberType NoteProperty -Name "sessionId" -Value $Measurement.userSessionId
        $null = $LoginTimesCollection.Add($LoginTime)
    }

    $LoginTimesCollection | Export-Csv -Path "$($Folder)\Raw Login Times.csv" -NoTypeInformation

    #endregion Session Measurements and Logon Times

    #region LE Session Metrics
    if ($SessionMetricsEnabled -eq $true) {
        Write-Log -Message "[DATA EXPORT] Processing Login Enterprise Session metrics" -Level Info
        # LE Session Metric Measurements. This uses the v7-preview API to pull LE Session Metrics Measurements (WMI counters)

        # start a timer for gathering session metrics
        $SessionMetricGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

        # Use an Array List for better data handling
        $SessionMetricMeasurements = [System.Collections.ArrayList] @()

        $SessionMetricMeasurementsBatch = Get-LESessionMetricMeasurements -testRunId $testRun.Id -orderBy timestamp
        # returns timestamp,testrunId,userSessionKey,measurement,displayName,unit,instance,tag,fieldName

        if (($SessionMetricMeasurementsBatch | Measure-Object).Count -gt 0) {

            ##$SessionMetricMeasurements = $SessionMetricMeasurements | Select-Object displayName,instance,fieldName,timestamp,userSessionKey,@{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } },measurement
            $SessionMetricMeasurementsBatch = $SessionMetricMeasurementsBatch | Select-Object displayName, instance, fieldName, timestamp, userSessionKey, measurement

            # Add the SessionMetricMeasurementsBatch to the SessionMetricMeasurements ArrayList
            $SessionMetricMeasurements.AddRange($SessionMetricMeasurementsBatch)

            if (($SessionMetricMeasurements | Measure-Object).Count -eq 10000) {
                $FileEnded = $false
                while (-not $FileEnded) {
                    [int]$OffSet = $SessionMetricMeasurements.count + 1
                    Write-Log -Message "[DATA EXPORT] Pulling additional metrics from Login Enterprise with an offset of $($OffSet)" -Update -Level Info
                    $SessionMetricMeasurementsAdditional = Get-LESessionMetricMeasurements -testRunId $testRun.Id -orderBy timestamp -OffSet $OffSet
                    ##$SessionMetricMeasurementsAdditional = $SessionMetricMeasurementsAdditional | Select-Object displayName,instance,fieldName,timestamp,userSessionKey,@{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } },measurement
                    $SessionMetricMeasurementsAdditional = $SessionMetricMeasurementsAdditional | Select-Object displayName, instance, fieldName, timestamp, userSessionKey, measurement
                    # Add the SessionMetricMeasurementsAdditional to the SessionMetricMeasurements ArrayList
                    $SessionMetricMeasurements.AddRange($SessionMetricMeasurementsAdditional)
                    if (($SessionMetricMeasurementsAdditional | Measure-Object).count -lt 10000) {
                        $FileEnded = $true
                    }
                }
            }
            # stop the timer for gathering session metrics
            $SessionMetricGatheringStopWatch.Stop()
            $ElapsedTime = [math]::Round($SessionMetricGatheringStopWatch.Elapsed.TotalSeconds, 2)
            #Write-Log -Message " " -Level Info
            Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull $($SessionMetricMeasurements.Count) metrics from Login Enterprise" -Level Info

            Write-Log -Message "[DATA EXPORT] Identifying userSessions to hostName details from Login Enterprise" -Level Info
            #Create the Session HostName Map Array List
            $SessionHostNameMap = [System.Collections.ArrayList] @()

            # start a timer for gathering vmHost details
            $SessionHostNameMapStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

            foreach ($userSessionKey in ($SessionMetricMeasurements.userSessionKey | Select-Object -Unique)) {
                $SessionHostRecord = New-Object PSObject
                $SessionHostRecord | Add-Member -MemberType NoteProperty -Name "userSessionKey" -Value $userSessionKey
                $SessionHostRecord | Add-Member -MemberType NoteProperty -Name "hostName" -Value ((Get-LESessionDetails -testRunId $testRun.Id -userSessionId $userSessionKey).Properties | Where-Object { $_.propertyId -eq "TargetHost" }).value
                $null = $SessionHostNameMap.Add($SessionHostRecord)
            }

            # stop the timer for gathering vmHost details
            $SessionHostNameMapStopWatch.Stop()
            $ElapsedTime = [math]::Round($SessionHostNameMapStopWatch.Elapsed.TotalSeconds, 2)

            Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to identify userSessions to HostName from Login Enterprise" -Level Info
            
            if ($null -eq $SessionHostNameMap) {
                Write-Log -Message "[DATA EXPORT] No records were found in the session HostName Map" -Level Warn
                Continue
            }

            # Open an Arraylist to capture the update info prior to export
            $SessionMetricMeasurementsWithHost = [System.Collections.ArrayList] @()

            Write-Log -Message "[DATA EXPORT] Altering session Metrics with HostName details from Login Enterprise" -Level Info
            # start a timer for procesing Session Metrics with HostName
            $ItemProcessingStopWatch = [System.Diagnostics.Stopwatch]::StartNew()

            $SessionMetricMeasurementsCount = $SessionMetricMeasurements.Count # for tracking output only

            $ProcessedData = 0
            foreach ($item in $SessionMetricMeasurements) {
                $SessionMetricMeasurementsWithHostresult = New-Object PSObject
                $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "timestamp" -Value $item.timestamp
                $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "userSessionKey" -Value $item.userSessionKey
                $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "displayName" -Value $item.displayName
                $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "measurement" -Value $item.measurement
                $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "fieldName" -Value $item.fieldName
                $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "instance" -Value $item.instance
                $SessionMetricMeasurementsWithHostresult | Add-Member -MemberType NoteProperty -Name "hostName" -Value ($SessionHostNameMap | Where-Object { $_.userSessionKey -eq $item.userSessionKey }).hostName

                # Add the SessionMetricMeasurementsWithHostresult to the SessionMetricMeasurementsWithHost ArrayList
                $null = $SessionMetricMeasurementsWithHost.Add($SessionMetricMeasurementsWithHostresult)
                $ProcessedData ++ # Append a processed count for tracking output

                # for tracking output only, write an output for every 50000 records processed
                if ($ProcessedData % 50000 -eq 0 -and $ProcessedData -ne $SessionMetricMeasurementsCount) { 
                    Write-Log -Message "[DATA EXPORT] Processed $($ProcessedData) items out of $($SessionMetricMeasurementsCount)" -Update -Level Info
                }
                elseif ($ProcessedData -eq $SessionMetricMeasurementsCount) {
                    Write-Log -Message "[DATA EXPORT] Processed $($ProcessedData) items out of $($SessionMetricMeasurementsCount)" -Update -Level Info
                }
            } 

            # stop the timer for procesing Session Metrics with HostName
            $ItemProcessingStopWatch.Stop()
            $ElapsedTime = [math]::Round($ItemProcessingStopWatch.Elapsed.TotalMinutes, 2)
            #Write-Log -Message " " -Level Info
            Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) Minutes to alter $($SessionMetricMeasurementsWithHost.Count) records with HostName" -Level Info

            # Set the Data set ready for export
            if ($SessionMetricMeasurements.Count -eq $SessionMetricMeasurementsWithHost.Count) {
                Write-Log -Message "[DATA EXPORT] No Records were lost in the process" -Level Info
            }
            else {
                Write-Log -Message "[DATA EXPORT] Lost $(($SessionMetricMeasurements.Count - $SessionMetricMeasurementsWithHost.Count)) records in the process" -Level Warn
            }

            # Rest the SessionMetricMeasurements to the SessionMetricMeasurementsWithHost ready for export
            $SessionMetricMeasurements = $SessionMetricMeasurementsWithHost

            $SessionMetricMeasurements | Export-Csv -Path "$($Folder)\VM Perf Metrics.csv" -NoTypeInformation
        }
    }   
    #endregion LE Session Metrics

    #region Applications and Application Measurements
    Write-Log -Message "[DATA EXPORT] Processing Login Enterprise application measurement metrics" -Level Info

    #lookup table
    $Applications = Get-LEApplications
    Write-Log -Message "[DATA EXPORT] Found $($Applications.Count) applications in Login Enterprise" -Level Info

    # start a timer for gathering session metrics
    $AppMeasurementsGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

    # Use an Array List for better data handling
    $AppMeasurements = [System.Collections.ArrayList] @()

    Write-Log -Message "[DATA EXPORT] Pulling application measurements from Login Enterprise " -Level Info

    $AppMeasurementsBatch = Get-LEMeasurements -testRunId $testRun.Id -include "applicationMeasurements"
    #id, offsetInSeconds, result, userSessionId, appexecutionId, applicationName
    #$AppMeasurementsBatch = $AppMeasurementsBatch | Select-Object measurementId, timestamp, @{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } }, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
    $AppMeasurementsBatch = $AppMeasurementsBatch | Select-Object measurementId, timestamp, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }

    # Add the AppMeasurementsBatch to the AppMeasurements ArrayList
    $AppMeasurements.AddRange($AppMeasurementsBatch)

    if ($AppMeasurements.count -eq 10000) {
        $FileEnded = $false
        while (-not $FileEnded) {
            [int]$OffSet = $AppMeasurements.count + 1
            Write-Log -Message "[DATA EXPORT] Pulling additional metrics from Login Enterprise with an offset of $($OffSet)" -Update -Level Info
            $AppMeasurementsAdditional = Get-LEMeasurements -testRunId $testRun.Id -include "applicationMeasurements" -OffSet $OffSet
            #$AppMeasurementsAdditional = $AppMeasurementsAdditional | Select-Object measurementId, timestamp, @{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } }, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
            $AppMeasurementsAdditional = $AppMeasurementsAdditional | Select-Object measurementId, timestamp, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
            # Add the AppMeasurementsAdditional to the AppMeasurements ArrayList
            $AppMeasurements.AddRange($AppMeasurementsAdditional)
            if ($AppMeasurementsAdditional.count -lt 10000) {
                $FileEnded = $true
            } 
        }
    }

    $AppMeasurementsGatheringStopWatch.Stop()
    $ElapsedTime = [math]::Round($AppMeasurementsGatheringStopWatch.Elapsed.TotalSeconds, 2)
    #Write-Log -Message " " -Level Info
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull $($AppMeasurements.Count) metrics from Login Enterprise" -Level Info

    $AppMeasurements | Export-Csv -Path "$($Folder)\Raw AppMeasurements.csv" -NoTypeInformation
    #endregion Applications and Application Measurements

    #region VSI Results
    Write-Log -Message "[DATA EXPORT] Processing Login Enterprise VSI Results" -Level Info
    $VSIresults = Get-LEtestrunResults -testRunId $testRun.Id
    # create a VSI Collection Array list
    $VSICollection = [System.Collections.ArrayList] @()

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
        if ($result.euxScore.state -eq "disabled") {
            $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX score" -Value "0"
            $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX version" -Value "N/A"
        }
        Else {
            $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX score" -Value $result.euxScore.score
            $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX version" -Value $result.euxScore.version
        }
        $VSIresult | Add-Member -MemberType NoteProperty -Name "EUX state" -Value $result.euxScore.state
        if ($result.vsiMax.maxSessions -eq "") {
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax" -Value $result.loginCounts.totalCount
        }
        Else {
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax" -Value $result.vsiMax.maxSessions
        }
        if ($result.vsiMax.state -eq "disabled") {
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax version" -Value "N/A"
        }
        Else {
            $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax version" -Value $result.vsiMax.version
        }
        $VSIresult | Add-Member -MemberType NoteProperty -Name "vsiMax state" -Value $result.vsiMax.state
        $VSIresult | Add-Member -MemberType NoteProperty -Name "Comment" -Value $result.comment
        $VSIresult | Add-Member -MemberType NoteProperty -Name "started" -Value $result.started
        $VSIresult | Add-Member -MemberType NoteProperty -Name "finished" -Value $result.finished
        #Add the VSIresult to the VSICollection ArrayList
        $null = $VSICollection.Add($VSIresult)
    }
    $VSICollection | Export-Csv -Path "$($Folder)\VSI-results.csv" -NoTypeInformation
    #endregion VSI Results

    #region EUX Measurements
   
    if ($VSI_Target_EUXEnabled) {
        Write-Log -Message "[DATA EXPORT] Processing Login Enterprise EUX measurements" -Level Info

        Write-Log -Message "[DATA EXPORT] Pulling Login Enterprise Raw EUX Measurements metrics" -Level Info

        # start a timer for gathering EUX metrics
        $EUXMeasurementsGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
        $EUXMeasurements = Get-LERawEUX -testRunId $testRun.Id
        # stop the timer for gathering EUX metrics
        $EUXMeasurementsGatheringStopWatch.stop()
        $ElapsedTime = [math]::Round($EUXMeasurementsGatheringStopWatch.Elapsed.TotalSeconds, 2)
        Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) Seconds to pull $($EUXMeasurements.Count) metrics from Login Enterprise" -Level Info

        # Create the TimerCollection Array List
        $TimerCollection = [System.Collections.ArrayList] @()

        Write-Log -Message "[DATA EXPORT] Handling EUX Timer measurements" -Level Info

        foreach ($Measurement in $EUXMeasurements) {
            $EuxUser = $Measurement.euxMeasurements
            foreach ($EuxMeasurement in $EuxUser) {
                $Timer = New-Object PSObject
                $Timer | Add-Member -MemberType NoteProperty -Name "userSessionid" -Value $Measurement.UserSessionId
                $Timer | Add-Member -MemberType NoteProperty -Name "timestamp" -Value $EuxMeasurement.timestamp
                $Timer | Add-Member -MemberType NoteProperty -Name "timer" -Value $EuxMeasurement.timer
                $Timer | Add-Member -MemberType NoteProperty -Name "duration" -Value $EuxMeasurement.duration
                # Add the Timer to the TimerCollection ArrayList
                $null = $TimerCollection.Add($Timer)
            }
        }

        $TimerCollection | Export-Csv -Path "$($Folder)\Raw Timer Results.csv" -NoTypeInformation

        Write-Log -Message "[DATA EXPORT] Pulling Login Enterprise test run results" -Level Info

        # start a timer for gathering $EUXMeasurements test run results
        $EUXMeasurementsStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

        $EUXMeasurements = Get-LEtestrunResults -testRunId $testRun.Id -path "/eux-results"
        # stop the timer for gathering $EUXMeasurements test run results
        $EUXMeasurementsStopWatch.stop()
        $ElapsedTime = [math]::Round($EUXMeasurementsStopWatch.Elapsed.TotalSeconds, 2)
        Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull $($EUXMeasurements.Count) metrics from Login Enterprise" -Level Info

        # Create the EUXCollection Array List
        $EUXCollection = [System.Collections.ArrayList] @()

        foreach ($Measurement in $EUXMeasurements) {
            $EUXscore = New-Object PSObject
            $EUXscore | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $Measurement.timestamp
            $EUXscore | Add-Member -MemberType NoteProperty -Name "EUXScore" -Value $Measurement.score
            $null = $EUXCollection.Add($EUXscore)
        }


        $EUXCollection | Export-Csv -Path "$($Folder)\EUX-score.csv" -NoTypeInformation

        ## EUX timer results
        Write-Log -Message "[DATA EXPORT] Pulling Login Enterprise EUX Timer Result Measurements" -Level Info

        # Start a timer for gathering EUX timer results
        $EUXtimerMeasurementsStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

        $EUXtimerMeasurements = Get-LEtestrunResults -testRunId $testRun.Id -path "/eux-timer-results?euxTimer=diskMyDocs&euxTimer=diskMyDocsLatency&euxTimer=diskAppData&euxTimer=diskAppDataLatency&euxTimer=cpuSpeed&euxTimer=highCompression&euxTimer=fastCompression&euxTimer=appSpeed&euxTimer=appSpeedUserInput"
        # Stop the timer for gathering EUX timer results
        $EUXtimerMeasurementsStopWatch.stop()
        $ElapsedTime = [math]::Round($EUXtimerMeasurementsStopWatch.Elapsed.TotalSeconds, 2)
        Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull $($EUXtimerMeasurements.Count) metrics from Login Enterprise" -Level Info

        # Create the EUXtimerCollection Array List
        $EUXtimerCollection = [System.Collections.ArrayList] @()

        foreach ($timerMeasurement in $EUXtimerMeasurements) {
            $EUXtimerscore = New-Object PSObject
            $EUXtimerscore | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $timerMeasurement.timestamp
            $EUXtimerscore | Add-Member -MemberType NoteProperty -Name "EUXTimer" -Value $timerMeasurement.euxTimer
            $EUXtimerscore | Add-Member -MemberType NoteProperty -Name "Score" -Value $timerMeasurement.score
            # Add the EUXtimerscore to the EUXtimerCollection ArrayList
            $null = $EUXtimerCollection.Add($EUXtimerscore)
        }

        $EUXtimerCollection | Export-Csv -Path "$($Folder)\EUX-timer-score.csv" -NoTypeInformation
    }
    else {
        Write-Log -Message "[DATA EXPORT] Processing Login Enterprise test run results" -Level Info

        Write-Log -Message "[DATA EXPORT] Pulling Login Enterprise test run results" -Level Info
        
        $EUXMeasurements = Get-LEtestrunResults -testRunId $testRun.Id
        # Create the EUXCollection Array List
        $EUXCollection = [System.Collections.ArrayList] @()
        foreach ($Measurement in $EUXMeasurements) {
            $EUXscore = New-Object PSObject
            $EUXscore | Add-Member -MemberType NoteProperty -Name "TimeStamp" -Value $Measurement.started
            $EUXscore | Add-Member -MemberType NoteProperty -Name "EUXScore" -Value "0"
            $null = $EUXCollection.Add($EUXscore)
        }
        $EUXCollection | Export-Csv -Path "$($Folder)\EUX-score.csv" -NoTypeInformation
    }

    #endregion EUX Measurements
}