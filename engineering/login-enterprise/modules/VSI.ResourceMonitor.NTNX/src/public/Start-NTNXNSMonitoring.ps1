function Start-NTNXNSMonitoring {
    param(
        [Parameter(Mandatory = $true)] [Int32]$DurationInMinutes,
        [Parameter(Mandatory = $true)] [Int32]$RampupInMinutes,
        [Parameter(Mandatory = $false)] [switch]$AsJob,
        [Parameter(Mandatory = $true)] [string]$Path,
        [Parameter(Mandatory = $true)] [string]$OutputFolder,
        [Parameter(Mandatory = $false)] [string]$StopMonitoringCheckFile = "$env:temp\VSIMonitoring_Stop.chk"
    )

    $MonitoringScriptBlock = {
        param(
            $Path,
            $VSI_Target_NetScaler,
            $VSI_Target_NetScaler_Password,
            $DurationInMinutes,
            $RampupInMinutes,
            $OutputFolder,
            $StopMonitoringCheckFile
        )

        Import-Module "$Path\modules\VSI.ResourceMonitor.NTNX\src\internal\Invoke-NetScalerStats.ps1" -Force

        if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

        $Started = Get-Date
        $StartTimeStamp = Get-Date
        $StartTimeStamp = [DateTime]::new($StartTimeStamp.Year, $StartTimeStamp.Month, $StartTimeStamp.Day, $StartTimeStamp.Hour, $StartTimeStamp.Minute, 0)
    
        $StopMonitoring = $false
        $SampleSize = 30
    
        while ($StopMonitoring -eq $false) {
            $CurrentTime = Get-Date
            while ($StartTimeStamp.AddSeconds(60) -gt $CurrentTime) {
                Start-Sleep -Seconds 1
                $CurrentTime = Get-Date
            }
            
            $NSStats = "$($OutputFolder)\NetScaler Raw.csv"
            $NetScalerStats = Invoke-NetScalerStats -HostName $VSI_Target_NetScaler -Password $VSI_Target_NetScaler_Password
            
            $item = New-Object PSObject  
            $item | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp.ToUniversalTime()) -Format "o") -Force  
            $item | Add-Member -MemberType NoteProperty -Name "PacketEngineCPU" -Value $NetScalerStats.PacketEngineCPU -Force
            $item | Add-Member -MemberType NoteProperty -Name "ManagementEngineCPU" -Value $NetScalerStats.ManagementEngineCPU -Force
            $item | Add-Member -MemberType NoteProperty -Name "MemoryUsage" -Value $NetScalerStats.MemoryUsage -Force
            $item | Export-Csv -Path $NSStats -NoTypeInformation -Append

            $StartTimeStamp = $StartTimeStamp.AddSeconds($SampleSize)
            if ((New-TimeSpan -Start $Started -End (Get-Date)).TotalMinutes -ge ($DurationInMinutes + $RampupInMinutes)) { $StopMonitoring = $true }
            if (Test-Path $StopMonitoringCheckFile) { $StopMonitoring = $true }
        }
    }

    if ($AsJob.IsPresent) {
        Get-Job -Name NTNXNSMonitoringJob -ErrorAction Ignore | Stop-Job
        Get-Job -Name NTNXNSMonitoringJob -ErrorAction Ignore | Remove-Job
        return (Start-Job -ScriptBlock $MonitoringScriptBlock -Name NTNXNSMonitoringJob -ArgumentList @($Path, $VSI_Target_NetScaler, $VSI_Target_NetScaler_Password, $DurationInMinutes, $RampupInMinutes, $OutputFolder, $StopMonitoringCheckFile))
    }

}