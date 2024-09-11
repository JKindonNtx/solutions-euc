function Get-Prometheusdata {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$TestStarttime,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $true)][String]$Prometheusip,
        [Parameter(Mandatory = $true)][string]$OutputFolder
    )

    $starttime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date -Date $TestStarttime).ToUniversalTime())).TotalSeconds)
    $endTime = [math]::Round((New-TimeSpan -Start (Get-Date "1970-01-01") -End ((Get-Date).ToUniversalTime())).TotalSeconds)
    
    #region Getting Prometheus data

    Write-Log -Message "[DATA EXPORT] Getting Prometheus data" -Level Info

 
    # start a timer for gathering session metrics
    $PrometheusGatheringStopWatch = [system.Diagnostics.Stopwatch]::StartNew()
    $ClusterGPUPowerDrawfile = "$($OutputFolder)\ClusterGPU-Power.csv"

    $params = @{
        Prometheusip                = $Prometheusip 
        PrometheusQuery             = "sum(shell_nvidia_smi_q{target_id=~'.*',GPU_UUID=~'.*',target_type=~'.*',target_ip=~'.*',metric_unit='Watts',metric='GPU power draw'}) by (target_id)"
        starttime                   = $starttime
        endtime                     = $endtime 
    }
    $ClusterGPUPowerDraw = Invoke-PublicApiMethodPrometheus @params
    $params = $null

    if ($ClusterGPUPowerDraw.status -eq "success") {
        $ClusterGPUPowerDrawresults = New-Object PSObject  
        $metric = $ClusterGPUPowerDraw.data.result.metric.target_id
        foreach ($result in $ClusterGPUPowerDraw.data.result.values) {
            
            $ClusterGPUPowerDrawresults | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value $($result[0]) -Force
            $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "Cluster" -Value $metric -Force
            $ClusterGPUPowerDrawresults | Add-Member -MemberType Noteproperty -Name "Watts" -Value $($result[1]) -Force
            $ClusterGPUPowerDrawresults | Export-Csv -Path $ClusterGPUPowerDrawfile -NoTypeInformation -Appen
        }
    } else {
        Write-Host "Failed to retrieve data from Prometheus"
    }

    # stop the timer for gathering session metrics
    $PrometheusGatheringStopWatch.stop()
    $ElapsedTime = [math]::Round($PrometheusGatheringStopWatch.Elapsed.TotalSeconds, 2)
    Write-Log -Message "[DATA EXPORT] Took $($ElapsedTime) seconds to pull metrics from Prometheus" -Level Info

}