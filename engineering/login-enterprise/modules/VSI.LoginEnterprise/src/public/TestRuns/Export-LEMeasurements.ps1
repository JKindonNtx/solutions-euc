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
        $UserSessionsCollection | Export-Csv -Path "$($Folder)\User Sessions.csv"

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
        $LoginTimesCollection | Export-Csv -Path "$($Folder)\Raw Login Times.csv"

        $TimerCollection = @()
        foreach ($Measurement in $SessionMeasurements | Where-Object { $_.measurementId -ne "connection" -and $_.measurementId -ne "group_policies" -and $_.measurementId -ne "total_login_time" -and $_.measurementId -ne "user_profile" -and $_.measurementId -ne "euxscore" }) {
            $Timer = New-Object PSObject
            $Timer | Add-Member -MemberType NoteProperty -Name "id" -Value ($Measurement.measurementId -replace "eux_", "")
            $Timer | Add-Member -MemberType NoteProperty -Name "offsetInSeconds" -Value ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $Measurement.timestamp)).TotalSeconds)
            $Timer | Add-Member -MemberType NoteProperty -Name "result" -Value $Measurement.duration
            $Timer | Add-Member -MemberType NoteProperty -Name "sessionId" -Value $Measurement.userSessionId
            $TimerCollection += $Timer
        }
        $TimerCollection | Export-Csv -Path "$($Folder)\Raw Timer Results.csv"
    
        #lookup table
        $Applications = Get-LEApplications

        $AppMeasurements = Get-LEMeasurements -testRunId $testRun.Id -include "applicationMeasurements"
        #id, offsetInSeconds, result, userSessionId, appexecutionId, applicationName
        $AppMeasurements = $AppMeasurements | Select-Object measurementId, @{Name = "offSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.timestamp)).TotalSeconds) } }, userSessionId, @{Name = "result"; Expression = { $_.duration } }, appexecutionId, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
        $AppMeasurements | Export-Csv -Path "$($Folder)\Raw AppMeasurements.csv"
   
        $AppExecutions = @()
        foreach ($UserSession in $UserSessions) {
            $ApplicationExecutions = Get-LEAppExecutions -testRunId $TestRun.Id -UserSessionId $UserSession.id
            #id,state, userSessionId, startOffset, endOffset, applicationName
            $ApplicationExecutions = $ApplicationExecutions | Select-Object id, state, userSessionId, @{Name = "startOffSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.created)).TotalSeconds) } }, @{Name = "endOffSetInSeconds"; Expression = { ((New-TimeSpan -Start (Get-Date $TestRun.started) -End (Get-Date $_.lastModified)).TotalSeconds) } }, @{Name = "applicationName"; Expression = { Foreach ($App in $Applications) { if ($App.id -eq $_.applicationId) { $app.Name } } } }
            $AppExecutions += $ApplicationExecutions
        }
        $AppExecutions | Export-Csv -Path "$($Folder)\Raw AppExecutions.csv"


     
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