function Start-VSINTNXMonitoring {
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Int32]$DurationInMinutes,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [Int32]$RampupInMinutes,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [string]$Hostuuid,
        [Parameter(Mandatory = $false, ParameterSetName = 'TestMonitoring')]
        [switch]$AsJob,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [string]$IPMI_ip,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [string]$OutputFolder,
        [Parameter(Mandatory = $true, ParameterSetName = 'TestMonitoring')]
        [string]$NTNXCounterConfigurationFile = ".\ReportConfigurationNTNX.jsonc",
        [Parameter(Mandatory = $false, ParameterSetName = 'TestMonitoring')]
        [string]$StopMonitoringCheckFile = "$env:temp\VSIMonitoring_Stop.chk"
    )

    $NTNXCounterConfiguration = Get-Content $NTNXCounterConfigurationFile | ConvertFrom-Json

    $MonitoringScriptBlock = {
        param(
            $Hostuuid,
            $IPMI_ip,
            $DurationInMinutes,
            $RampupInMinutes,
            $OutputFolder,
            $NTNXCounterConfiguration,
            $StopMonitoringCheckFile
        )

        if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

        $Started = Get-Date
        $StartTimeStamp = Get-Date
        $StartTimeStamp = [DateTime]::new($StartTimeStamp.Year, $StartTimeStamp.Month, $StartTimeStamp.Day, $StartTimeStamp.Hour, $StartTimeStamp.Minute, 0)
    
        $StopMonitoring = $false
        $SampleSize = 20
    
        while ($StopMonitoring -eq $false) {
            $CurrentTime = Get-Date
            while ($StartTimeStamp.AddSeconds(60) -gt $CurrentTime) {
                Start-Sleep -Seconds 1
                $CurrentTime = Get-Date
            }
            
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
            if ((New-TimeSpan -Start $Started -End (Get-Date)).TotalMinutes -ge ($DurationInMinutes + $RampupInMinutes)) { $StopMonitoring = $true }
            if (Test-Path $StopMonitoringCheckFile) { $StopMonitoring = $true }
        }
    }

    if ($AsJob.IsPresent) {
        Get-Job -Name VSIMonitoringJob -ErrorAction Ignore | Stop-Job
        Get-Job -Name VSIMonitoringJob -ErrorAction Ignore | Remove-Job
        return (Start-Job -ScriptBlock $MonitoringScriptBlock -Name VSIMonitoringJob -ArgumentList @($Hostuuid, $IPMI_ip, $DurationInMinutes, $RampupInMinutes, $OutputFolder, $NTNXCounterConfiguration, $StopMonitoringCheckFile))
    }

}