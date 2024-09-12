function Get-Prometheusdata {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestStarttime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$Prometheusip,
        [Parameter(Mandatory = $true)][string]$OutputFolder,
        [Parameter(Mandatory = $false)][switch]$GPU,
        [Parameter(Mandatory = $false)][switch]$Files
    )

    $starttime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestStarttime).ToUniversalTime())).TotalSeconds)
    $endTime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date).ToUniversalTime())).TotalSeconds)
    
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
                        $timestamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime.ToLocalTime()).ToString("s") 
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "Cluster" -Value $($result.metric.target_id) -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "ProductName" -Value $($result.metric.ProductName) -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "hostip" -Value $($result.metric.target_ip) -Force
                        $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "GPU_UUID" -Value $($result.metric.GPU_UUID) -Force
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
        #placeholder for Files
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
                    $timestamp = (([System.DateTimeOffset]::FromUnixTimeSeconds($($subvalue[0]))).DateTime.ToLocalTime()).ToString("s") 
                    $ClusterPowerUsageresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $timestamp -Force
                    $ClusterPowerUsageresults | Add-Member -MemberType Noteproperty -Name "hostip" -Value $($result.metric.host_ip) -Force
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