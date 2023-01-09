function Start-VSINTNXMonitoring {
    ##############################
    #.SYNOPSIS
    #Captures performance data
    #
    #.DESCRIPTION
    #Captures performance data from the specified hypervisor
    #	
    #.PARAMETER HostName
    #Hostname of the hypervisor
    #
    #.PARAMETER TestName
    #Name of the active test	
    #
    #.PARAMETER Duration
    #The duration of the test
    #
    #.EXAMPLE
    #Capture-HostData -HostName "VAL-TARGET3" -TestName "Win10_TEST_run_1" -Duration 2880
    #
    #.NOTES
    #Initial creation of generic function
    ##############################
    Param
    (
        [string]$Hostuuid,
        [string]$IPMI_ip,
        [Int32]$DurationInMinutes,
        [Int32]$RampupInMinutes,
        [switch]$AsJob,
        [string]$OutputFolder,
        [string]$NTNXCounterConfigurationFile = ".\ReportConfigurationNTNX.jsonc",
        [string]$StopMonitoringCheckFile = "$env:temp\VSIMonitoring_Stop.chk"
    )
    $NTNXCounterConfiguration = Get-Content $NTNXCounterConfigurationFile | ConvertFrom-Json

    if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

    $Started = Get-Date
    $StartTimeStamp = Get-Date
    $StartTimeStamp = [DateTime]::new($StartTimeStamp.Year, $StartTimeStamp.Month, $StartTimeStamp.Day, $StartTimeStamp.Hour, $StartTimeStamp.Minute, 0)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    
    $StopMonitoring = $false
    $SampleSize = 20
    
    while ($StopMonitoring -eq $false) {
        $CurrentTime = Get-Date
        while ($StartTimeStamp.AddSeconds(60) -gt $CurrentTime) {
            #Write-Host "$(Get-Date) Waiting while $($StartTimeStamp.AddSeconds(60)) is gt $CurrentTime"
            Start-Sleep -Seconds 1
            $CurrentTime = Get-Date
        }
        $EndTimeStamp = $STarttimeStamp.AddSeconds($SampleSize)


    $file = "$($OutputFolder)\Host Raw.csv"

            $results = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts/$($hostuuid)/stats/?metrics=hypervisor_cpu_usage_ppm&metrics=hypervisor_memory_usage_ppm"
            $resultsPower = Invoke-PublicApiMethodRedfish -IPMI_ip $IPMI_ip -Method "GET" -Path "Chassis/1/Power"

            $item = New-Object PSObject  
            $item | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp.ToUniversalTime()) -Format "o") -Force  
            foreach ($result in $results.stats_specific_responses) {
                if ($result.metric -eq "hypervisor_cpu_usage_ppm" -Or $result.metric -eq "hypervisor_memory_usage_ppm") {
                    $actualvalue = $result.values[0] / 10000
                    $item | Add-Member Noteproperty $result.metric $actualvalue
                }
                else {
                    $item | Add-Member Noteproperty $result.metric $result.values[0]
                }
            }
            $item | Add-Member Noteproperty "PowerConsumedWatts" $resultsPower.PowerControl.PowerConsumedWatts
            $item | Export-Csv -Path $File -NoTypeInformation -Append

            $StartTimeStamp = $StartTimeStamp.AddSeconds($SampleSize)
        #    Start-Sleep -Seconds $delay
            #$i++
        #} While ($i -ne $Samples)
        if ((New-TimeSpan -Start $Started -End (Get-Date)).TotalMinutes -ge ($DurationInMinutes + $RampupInMinutes)) { $StopMonitoring = $true }
        if (Test-Path $StopMonitoringCheckFile) { $StopMonitoring = $true }
    }

}