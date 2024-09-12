function Get-Prometheusdata {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestStarttime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestFinishtime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$Prometheusip,
        [Parameter(Mandatory = $true)][string]$OutputFolder,
        [Parameter(Mandatory = $false)][switch]$GPU,
        [Parameter(Mandatory = $false)][switch]$Files
    )

    $starttime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestStarttime).ToUniversalTime())).TotalSeconds)
    $endTime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestFinishtime).ToUniversalTime())).TotalSeconds)
    
    #region Getting Prometheus data

    Write-Log -Message "[DATA EXPORT] Getting Prometheus data" -Level Info

 
    # start a timer for gathering session metrics
    $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
   
    if ($GPU){
        $ClusterGPUPowerDrawfile = "$($OutputFolder)\Prom-ClusterGPU-Power.csv"

        $params = @{
            Prometheusip                = $Prometheusip 
            PrometheusQuery             = "shell_nvidia_smi_q{target_id=~'.*',GPU_UUID=~'.*',target_type=~'.*',target_ip=~'.*',metric_unit='Watts',metric='GPU power draw'}"
            starttime                   = $starttime
            endtime                     = $endtime 
        }
        $ClusterGPUPowerDraw = Invoke-PublicApiMethodPrometheus @params
        $params = $null
    
       if ($ClusterGPUPowerDraw.status -eq "success") {
            $ClusterGPUPowerDrawresults = New-Object PSObject  
            foreach ($result in $ClusterGPUPowerDraw.data.result) {
                foreach ($value in $result) {
                    foreach ($subvalue in $value.values) {
                        $timestamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") 
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "prom_Cluster" -Value $($result.metric.target_id) -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "prom_ProductName" -Value $($result.metric.ProductName) -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "prom_hostip" -Value $($result.metric.target_ip) -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "prom_GPU_UUID" -Value $($result.metric.GPU_UUID) -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "Watts" -Value $($subvalue[1]) -Force
                        $ClusterGPUPowerDrawresults | Export-Csv -Path $ClusterGPUPowerDrawfile -NoTypeInformation -Appen
                    }
                }
            }
        } else {
            Write-Log -Message "Failed to retrieve GPU data from Prometheus" -Level Error
        }
    }

    if ($Files){
        $ClusterFilesIOPSfile = "$($OutputFolder)\Prom-ClusterFilesIOPS.csv"

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
                        $timestamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") 
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
            Write-Log -Message "Failed to retrieve GPU data from Prometheus" -Level Error
        }
    }

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
                    $timestamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime).ToString("s") 
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
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull metrics from Prometheus" -Level Info
}