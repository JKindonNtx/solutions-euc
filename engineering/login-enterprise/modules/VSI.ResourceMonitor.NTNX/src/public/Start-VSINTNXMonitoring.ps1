function Start-VSINTNXMonitoring {
    param(
        [Parameter(Mandatory = $true)] [Int32]$DurationInMinutes,
        [Parameter(Mandatory = $true)] [Int32]$RampupInMinutes,
        [Parameter(Mandatory = $true)] [string]$Hostuuid,
        [Parameter(Mandatory = $false)] [switch]$AsJob,
        [Parameter(Mandatory = $true)] [string]$IPMI_ip,
        [Parameter(Mandatory = $true)] [string]$Path,
        [Parameter(Mandatory = $true)] [string]$OutputFolder,
        [Parameter(Mandatory = $true)] [string]$NTNXCounterConfigurationFile = ".\ReportConfigurationNTNX.jsonc",
        [Parameter(Mandatory = $false)] [string]$StopMonitoringCheckFile = "$env:temp\VSIMonitoring_Stop.chk"
    )

    $NTNXCounterConfiguration = Get-Content $NTNXCounterConfigurationFile | ConvertFrom-Json

    $MonitoringScriptBlock = {
        param(
            $Path,
            $Hostuuid,
            $VSI_Target_CVM,
            $VSI_Target_CVM_admin,
            $VSI_Target_CVM_Password,
            $IPMI_ip,
            $VSI_Target_IPMI_admin,
            $VSI_Target_IPMI_Password,
            $DurationInMinutes,
            $RampupInMinutes,
            $OutputFolder,
            $NTNXCounterConfiguration,
            $StopMonitoringCheckFile
        )
        Import-Module "$Path\modules\VSI.ResourceMonitor.NTNX\src\internal\Invoke-PublicApiMethodNTNX.ps1" -Force
        Import-Module "$Path\modules\VSI.ResourceMonitor.NTNX\src\internal\Invoke-PublicApiMethodRedfish.ps1" -Force

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

            $results = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts/$($Hostuuid)/stats/?metrics=hypervisor_cpu_usage_ppm&metrics=hypervisor_memory_usage_ppm"
            $resultsPower = Invoke-PublicApiMethodRedfish -IPMI_ip $IPMI_ip -Method "GET" -Path "Chassis/1/Power"

            $item = New-Object PSObject  
            $item | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp) -Format "o") -Force  
            
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
        return (Start-Job -ScriptBlock $MonitoringScriptBlock -Name VSIMonitoringJob -ArgumentList @($Path, $Hostuuid, $VSI_Target_CVM, $VSI_Target_CVM_admin, $VSI_Target_CVM_Password, $IPMI_ip, $VSI_Target_IPMI_admin, $VSI_Target_IPMI_Password, $DurationInMinutes, $RampupInMinutes, $OutputFolder, $NTNXCounterConfiguration, $StopMonitoringCheckFile))
    }

}