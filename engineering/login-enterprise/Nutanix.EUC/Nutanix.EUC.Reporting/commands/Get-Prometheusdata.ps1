function Get-Prometheusdata {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestStarttime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestFinishtime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$Prometheusip,
        [Parameter(Mandatory = $true)][string]$OutputFolder,
        [Parameter(Mandatory = $false)][switch]$MainProm,
        [Parameter(Mandatory = $false)][switch]$GPU,
        [Parameter(Mandatory = $false)][switch]$Files
    )

    $starttime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestStarttime).ToUniversalTime())).TotalSeconds)
    $endTime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestFinishtime).ToUniversalTime())).TotalSeconds)
    
    #region Getting Prometheus data

    Write-Log -Message "[DATA EXPORT] Getting Prometheus data" -Level Info
    
    if ($MainProm){
        Write-Log -Message "[DATA EXPORT] Getting Cluster Power Prometheus data" -Level Info
        # start a timer for gathering session metrics
        $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

        $ClusterPowerUsagefile = "$($OutputFolder)\Prom-Cluster-PowerUsage.csv"

        $params = @{
            Prometheusip                = $Prometheusip 
            PrometheusQuery             = "sum(nutanix_shell_hostssh_ipmitool_dcmi_power_reading{target_id=~'.+',target_type='CVM',host_ip=~'.+',metric='Instantaneous power reading',metric_unit='Watts'}) by (host_ip)"
            starttime                   = $starttime
            endtime                     = $endtime 
        }
        $ClusterPowerUsage = Invoke-PublicApiMethodPrometheus @params
        $params = $null

   if ($ClusterPowerUsage.status -eq "success") {
        $ClusterPowerUsageresults = New-Object PSObject  
        foreach ($result in $ClusterPowerUsage.data.result) {
            foreach ($value in $result) {
                foreach ($subvalue in $value.values) {
                    $timestamp = (get-date (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") -Format "u") 
                    $ClusterPowerUsageresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                    $ClusterPowerUsageresults | Add-Member -MemberType Noteproperty -Name "prom_hostip" -Value $($result.metric.host_ip) -Force
                    $ClusterPowerUsageresults | Add-Member -MemberType Noteproperty -Name "Watts" -Value $($subvalue[1]) -Force
                    $ClusterPowerUsageresults | Export-Csv -Path $ClusterPowerUsagefile -NoTypeInformation -Appen
                }
            }
        }
    } else {
        Write-Log -Message "Failed to retrieve Host Power data from Prometheus" -Level Error
    }
    # stop the timer for gathering session metrics
    $PrometheusGatheringStopWatch.stop()
    $ElapsedTime = [math]::Round($PrometheusGatheringStopWatch.Elapsed.TotalSeconds, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull Cluster Power metrics from Prometheus" -Level Info

    Write-Log -Message "[DATA EXPORT] Getting Cluster CPU Prometheus data" -Level Info
    # start a timer for gathering session metrics
    $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

    $ClusterCPUUsagefile = "$($OutputFolder)\Prom-Cluster-CPUUsage.csv"

    $params = @{
        Prometheusip                = $Prometheusip 
        PrometheusQuery             = "avg(nutanix_shell_cpupower_monitor{target_id=~'.+',target_type=~'.+',target_ip=~'.+',metric_name=~'Mperf C0|Mperf Cx'}) by (target_ip,metric_name)"
        starttime                   = $starttime
        endtime                     = $endtime 
    }
    $ClusterCPUUsage = Invoke-PublicApiMethodPrometheus @params
    $params = $null

   if ($ClusterCPUUsage.status -eq "success") {
        $ClusterCPUUsageresults = New-Object PSObject  
        foreach ($result in $ClusterCPUUsage.data.result) {
            foreach ($value in $result) {
                foreach ($subvalue in $value.values) {
                    $timestamp = (get-date (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") -Format "u") 
                    $ClusterCPUUsageresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                    $ClusterCPUUsageresults | Add-Member -MemberType Noteproperty -Name "prom_hostip" -Value $($result.metric.target_ip) -Force
                    $ClusterCPUUsageresults | Add-Member -MemberType Noteproperty -Name "prom_metric" -Value $($result.metric.metric_name) -Force
                    $ClusterCPUUsageresults | Add-Member -MemberType Noteproperty -Name "Percent" -Value $($subvalue[1]) -Force
                    $ClusterCPUUsageresults | Export-Csv -Path $ClusterCPUUsagefile -NoTypeInformation -Appen
                }
            }
        }
    } else {
        Write-Log -Message "Failed to retrieve Host CPU data from Prometheus" -Level Error
    }
    # stop the timer for gathering session metrics
    $PrometheusGatheringStopWatch.stop()
    $ElapsedTime = [math]::Round($PrometheusGatheringStopWatch.Elapsed.TotalSeconds, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull Host CPU metrics from Prometheus" -Level Info

    Write-Log -Message "[DATA EXPORT] Getting Cluster CVM IOstat Prometheus data" -Level Info
    # start a timer for gathering session metrics
    $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

    $ClusterCVMiostatfile = "$($OutputFolder)\Prom-Cluster-CVMUsage.csv"

    $params = @{
        Prometheusip                = $Prometheusip 
        PrometheusQuery             = "avg(nutanix_shell_iostat_x_m_y_3_1{target_id=~'.+',target_type='CVM',target_ip=~'.+',Device=~'sd.+|.*nvme.*',metric=~'.+'}) by (target_ip,metric,Device)"   
        starttime                   = $starttime
        endtime                     = $endtime 
    }
    $ClusterCVMiostat = Invoke-PublicApiMethodPrometheus @params
    $params = $null

   if ($ClusterCVMiostat.status -eq "success") {
        $ClusterCVMiostatresults = New-Object PSObject  
        foreach ($result in $ClusterCVMiostat.data.result) {
            foreach ($value in $result) {
                foreach ($subvalue in $value.values) {
                    $timestamp = (get-date (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") -Format "u") 
                    $ClusterCVMiostatresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                    $ClusterCVMiostatresults | Add-Member -MemberType Noteproperty -Name "prom_cvmip" -Value $($result.metric.target_ip) -Force
                    $ClusterCVMiostatresults | Add-Member -MemberType Noteproperty -Name "prom_metric_device" -Value $($result.metric.Device) -Force
                    $ClusterCVMiostatresults | Add-Member -MemberType Noteproperty -Name "prom_metric_name" -Value $($result.metric.metric) -Force
                    $ClusterCVMiostatresults | Add-Member -MemberType Noteproperty -Name "value" -Value $($subvalue[1]) -Force
                    $ClusterCVMiostatresults | Export-Csv -Path $ClusterCVMiostatfile -NoTypeInformation -Appen
                }
            }
        }
    } else {
        Write-Log -Message "Failed to retrieve CVM IOstat data from Prometheus" -Level Error
    }
    # stop the timer for gathering session metrics
    $PrometheusGatheringStopWatch.stop()
    $ElapsedTime = [math]::Round($PrometheusGatheringStopWatch.Elapsed.TotalSeconds, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull CVM IOstat metrics from Prometheus" -Level Info

    if ($GPU){
        Write-Log -Message "[DATA EXPORT] Getting GPU Prometheus data" -Level Info
        # start a timer for gathering session metrics
        $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

        $ClusterGPUfile = "$($OutputFolder)\Prom-ClusterGPU.csv"

        $params = @{
            Prometheusip                = $Prometheusip 
            PrometheusQuery             = "shell_nvidia_smi_q{target_id=~'.*',GPU_UUID=~'.*',target_type=~'.*',target_ip=~'.*',metric_unit=~'.*',metric=~'.*'}"
            starttime                   = $starttime
            endtime                     = $endtime 
        }
        $ClusterGPU = Invoke-PublicApiMethodPrometheus @params
        $params = $null
    
       if ($ClusterGPU.status -eq "success") {
            $ClusterGPUresults = New-Object PSObject  
            foreach ($result in $ClusterGPU.data.result) {
                foreach ($value in $result) {
                    foreach ($subvalue in $value.values) {
                        $timestamp = (get-date (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") -Format "u")
                        $ClusterGPUresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "prom_Cluster" -Value $($result.metric.target_id) -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "prom_ProductName" -Value $($result.metric.ProductName) -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "prom_DriverVersion" -Value $($result.metric.DriverVersion) -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "prom_hostip" -Value $($result.metric.target_ip) -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "prom_GPU_UUID" -Value $($result.metric.GPU_UUID) -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "prom_metric_name" -Value $($result.metric.metric) -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "prom_metric_unit" -Value $($result.metric.metric_unit) -Force
                        $ClusterGPUresults | Add-Member -MemberType Noteproperty -Name "value" -Value $($subvalue[1]) -Force
                        $ClusterGPUresults | Export-Csv -Path $ClusterGPUfile -NoTypeInformation -Appen
                    }
                }
            }
        } else {
            Write-Log -Message "Failed to retrieve GPU data from Prometheus" -Level Error
        }
        # stop the timer for gathering session metrics
        $PrometheusGatheringStopWatch.stop()
        $ElapsedTime = [math]::Round($PrometheusGatheringStopWatch.Elapsed.TotalSeconds, 2)
        Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull GPU metrics from Prometheus" -Level Info
    }
    }

    if ($Files){
        Write-Log -Message "[DATA EXPORT] Getting Files FS IOPS Prometheus data" -Level Info
        # start a timer for gathering session metrics
        $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

        $ClusterFilesIOPSfile = "$($OutputFolder)\Prom-ClusterFiles-FS-IOPS.csv"

        $params = @{
            Prometheusip                = $Prometheusip 
            PrometheusQuery             = "sum(irate(node_afsFs_zpl_posix_exec_histo_ns_count{fs_name=~'.+', ops=~'.+', op_class=~'.+' }[15s])) by (fs_name,ops,op_class)"
            starttime                   = $starttime
            endtime                     = $endtime 
        }
        $ClusterFilesIOPS = Invoke-PublicApiMethodPrometheus @params
        $params = $null
    
       if ($ClusterFilesIOPS.status -eq "success") {
            $ClusterFilesIOPSresults = New-Object PSObject  
            foreach ($result in $ClusterFilesIOPS.data.result) {
                foreach ($value in $result) {
                    foreach ($subvalue in $value.values) {
                        $timestamp = (get-date (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") -Format "u") 
                        $ClusterFilesIOPSresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                        $ClusterFilesIOPSresults | Add-Member -MemberType Noteproperty -Name "prom_op_class" -Value $($result.metric.op_class) -Force
                        $ClusterFilesIOPSresults | Add-Member -MemberType Noteproperty -Name "prom_ops" -Value $($result.metric.ops) -Force
                        $ClusterFilesIOPSresults | Add-Member -MemberType Noteproperty -Name "prom_fs_name" -Value $($result.metric.fs_name) -Force
                        $ClusterFilesIOPSresults | Add-Member -MemberType Noteproperty -Name "ops" -Value $($subvalue[1]) -Force
                        $ClusterFilesIOPSresults | Export-Csv -Path $ClusterFilesIOPSfile -NoTypeInformation -Appen
                    }
                }
            }
        } else {
            Write-Log -Message "Failed to retrieve Files data from Prometheus" -Level Error
        }
        # stop the timer for gathering session metrics
        $PrometheusGatheringStopWatch.stop()
        $ElapsedTime = [math]::Round($PrometheusGatheringStopWatch.Elapsed.TotalSeconds, 2)
        Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull Files FS IOPS metrics from Prometheus" -Level Info

        Write-Log -Message "[DATA EXPORT] Getting Files Backend Prometheus data" -Level Info
        # start a timer for gathering session metrics
        $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()

        $ClusterFilesIOPSfile = "$($OutputFolder)\Prom-ClusterFiles-Backend-IOPS.csv"

        $params = @{
            Prometheusip                = $Prometheusip 
            PrometheusQuery             = "sum(irate(node_afsFs_ops_size_histo_bytes_count{fs_name=~'.+', dev_class=~'normal|meta' }[15s])) by (fs_name,dev_class)"
            starttime                   = $starttime
            endtime                     = $endtime 
        }
        $ClusterFilesIOPS = Invoke-PublicApiMethodPrometheus @params
        $params = $null
    
       if ($ClusterFilesIOPS.status -eq "success") {
            $ClusterFilesIOPSresults = New-Object PSObject  
            foreach ($result in $ClusterFilesIOPS.data.result) {
                foreach ($value in $result) {
                    foreach ($subvalue in $value.values) {
                        $timestamp = (get-date (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") -Format "u") 
                        $ClusterFilesIOPSresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                        $ClusterFilesIOPSresults | Add-Member -MemberType Noteproperty -Name "prom_dev_class" -Value $($result.metric.dev_class) -Force
                        $ClusterFilesIOPSresults | Add-Member -MemberType Noteproperty -Name "prom_fs_name" -Value $($result.metric.fs_name) -Force
                        $ClusterFilesIOPSresults | Add-Member -MemberType Noteproperty -Name "ops" -Value $($subvalue[1]) -Force
                        $ClusterFilesIOPSresults | Export-Csv -Path $ClusterFilesIOPSfile -NoTypeInformation -Appen
                    }
                }
            }
        } else {
            Write-Log -Message "Failed to retrieve Files data from Prometheus" -Level Error
        }
        # stop the timer for gathering session metrics
        $PrometheusGatheringStopWatch.stop()
        $ElapsedTime = [math]::Round($PrometheusGatheringStopWatch.Elapsed.TotalSeconds, 2)
        Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull Files Backend metrics from Prometheus" -Level Info
    }

}