function Start-VMMonitoring {
    param(
        [Parameter(Mandatory = $true)] [Int32]$DurationInMinutes,
        [Parameter(Mandatory = $false)] [switch]$AsJob,
        [Parameter(Mandatory = $true)] [string]$Path,
        [Parameter(Mandatory = $true)] [string]$OutputFolder,
        [Parameter(Mandatory = $true)] [string]$IP,
        [Parameter(Mandatory = $true)] [string]$UserName,
        [Parameter(Mandatory = $true)] [string]$Password,
        [Parameter(Mandatory = $true)] [string]$CollectionInterval,
        [Parameter(Mandatory = $true)] [string]$TargetVMIP
    )

    $MonitoringScriptBlock = {
        Param
        (
            $DurationInMinutes,
            $Path,
            $OutputFolder,
            $IP,
            $UserName,
            $Password,
            $CollectionInterval,
            $TargetVMIP
        )

        $Module = Join-Path -Path $Path -ChildPath "\modules\Nutanix.Invoke-PublicApiMethodv1.psm1"
        Import-Module $Module -Force

        if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

        $Started = Get-Date
        $StartTimeStamp = Get-Date
        $StartTimeStamp = [DateTime]::new($StartTimeStamp.Year, $StartTimeStamp.Month, $StartTimeStamp.Day, $StartTimeStamp.Hour, $StartTimeStamp.Minute, $StartTimeStamp.Second, 0)
    
        $StopMonitoring = $false
        $SampleSize = $CollectionInterval
    
        while ($StopMonitoring -eq $false) {
            $CurrentTime = Get-Date
            while ($StartTimeStamp.AddSeconds(60) -gt $CurrentTime) {
                Start-Sleep -Seconds 1
                $CurrentTime = Get-Date
            }
            
            $Stats = "$($OutputFolder)\VM Raw.csv"
            $VMs = Invoke-PublicApiMethodv1 -Method "GET" -Path "vms" -Cvm $IP -Password $Password -UserName $UserName 
            $NetScaler = $VMs.entities | Where-Object {$_.ipAddresses -like "*$($TargetVMIP)*" }          
            $item = New-Object PSObject  
            $item | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp.ToUniversalTime()) -Format "o") -Force 
            $CPUReady = $NetScaler.stats."hypervisor.cpu_ready_time_ppm" / 10000
            $CPUUsage = $NetScaler.stats."hypervisor_cpu_usage_ppm" / 10000
            $item | Add-Member -MemberType NoteProperty -Name "hypervisor.cpu_ready_time_ppm" -Value $CPUReady -Force
            $item | Add-Member -MemberType NoteProperty -Name "hypervisor_cpu_usage_ppm" -Value $CPUUsage -Force
            $item | Add-Member -MemberType NoteProperty -Name "hypervisor_num_received_bytes" -Value $NetScaler.stats."hypervisor_num_received_bytes" -Force
            $item | Add-Member -MemberType NoteProperty -Name "hypervisor_num_transmitted_bytes" -Value $NetScaler.stats."hypervisor_num_transmitted_bytes" -Force
            $item | Export-Csv -Path $Stats -NoTypeInformation -Append

            $StartTimeStamp = $StartTimeStamp.AddSeconds($SampleSize)
            if ((New-TimeSpan -Start $Started -End (Get-Date)).TotalMinutes -ge ($DurationInMinutes)) { $StopMonitoring = $true }
        }
    }

    if ($AsJob.IsPresent) {
        Get-Job -Name VMMonitoringJob -ErrorAction Ignore | Stop-Job
        Get-Job -Name VMMonitoringJob -ErrorAction Ignore | Remove-Job
        return (Start-Job -ScriptBlock $MonitoringScriptBlock -Name VMMonitoringJob -ArgumentList @($DurationInMinutes, $Path, $OutputFolder, $IP, $UserName, $Password, $CollectionInterval, $TargetVMIP))
    }

}