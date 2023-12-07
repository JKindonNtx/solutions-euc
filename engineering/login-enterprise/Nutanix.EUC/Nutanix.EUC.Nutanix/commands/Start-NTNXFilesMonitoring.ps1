function Start-NTNXFilesMonitoring {

    [CmdletBinding()]

    Param (
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
            $VSI_Target_Files,
            $VSI_Target_Files_api,
            $VSI_Target_Files_Password,
            $DurationInMinutes,
            $RampupInMinutes,
            $OutputFolder,
            $StopMonitoringCheckFile
        )
        
        $var_ModuleName = "Nutanix.EUC"
        Import-Module "$Path\$var_ModuleName\$var_ModuleName.psd1" -Force -ErrorAction Stop
    
        if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
    
        $Started = Get-Date
        $StartTimeStamp = Get-Date
        $StartTimeStamp = [DateTime]::new($StartTimeStamp.Year, $StartTimeStamp.Month, $StartTimeStamp.Day, $StartTimeStamp.Hour, $StartTimeStamp.Minute, 0)
        
        $StopMonitoring = $false
        $SampleSize = 300
        
        while ($StopMonitoring -eq $false) {
            $CurrentTime = Get-Date
            while ($StartTimeStamp.AddSeconds(60) -gt $CurrentTime) {
                Start-Sleep -Seconds 1
                $CurrentTime = Get-Date
            }
                
            $filesstats = "$($OutputFolder)\Files Raw.csv"
                
            try {
                $filesresults = Invoke-PublicApiMethodFiles -Method "GET" -Path "files/v4.0.a2/stats/file-server?metrics=number_of_files,number_of_connections,latency,throughput,iops,write_latency,read_latency,metadata_latency,write_throughput,read_throughput,read_iops,write_iops,metadata_iops" -ErrorAction Stop
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
    
            $filesitem = New-Object PSObject  
            $filesitem | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp.ToUniversalTime()) -Format "o") -Force  
    
            foreach ($filesresult in $filesresults.data) {
                $filesitem | Add-Member Noteproperty $filesresult.metric $filesresult.values.value
            }
            $filesitem | Export-Csv -Path $filesstats -NoTypeInformation -Appen
    
            $StartTimeStamp = $StartTimeStamp.AddSeconds($SampleSize)
            if ((New-TimeSpan -Start $Started -End (Get-Date)).TotalMinutes -ge ($DurationInMinutes + $RampupInMinutes)) { $StopMonitoring = $true }
            if (Test-Path $StopMonitoringCheckFile) { $StopMonitoring = $true }
        }
    }
    
    if ($AsJob.IsPresent) {
        Get-Job -Name NTNXFilesMonitoringJob -ErrorAction Ignore | Stop-Job
        Get-Job -Name NTNXFilesMonitoringJob -ErrorAction Ignore | Remove-Job
        return (Start-Job -ScriptBlock $MonitoringScriptBlock -Name NTNXFilesMonitoringJob -ArgumentList @($Path, $VSI_Target_Files, $VSI_Target_Files_api, $VSI_Target_Files_Password, $DurationInMinutes, $RampupInMinutes, $OutputFolder, $StopMonitoringCheckFile))
    }

}
