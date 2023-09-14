function Start-NetScalerMonitoring {
    param(
        [Parameter(Mandatory = $true)] [Int32]$DurationInMinutes,
        [Parameter(Mandatory = $false)] [switch]$AsJob,
        [Parameter(Mandatory = $true)] [string]$Path,
        [Parameter(Mandatory = $true)] [string]$OutputFolder,
        [Parameter(Mandatory = $true)] [string]$NSIP,
        [Parameter(Mandatory = $true)] [string]$NSUserName,
        [Parameter(Mandatory = $true)] [string]$NSPassword,
        [Parameter(Mandatory = $true)] [string]$NSCollectionInterval
    )

    $MonitoringScriptBlock = {
        Param
        (
            $DurationInMinutes,
            $Path,
            $OutputFolder,
            $NSIP,
            $NSUserName,
            $NSPassword,
            $NSCollectionInterval
        )

        $Module = Join-Path -Path $Path -ChildPath "\modules\Citrix.Invoke-NetScalerStats.psm1"
        Import-Module $Module -Force

        if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

        $Started = Get-Date
        $StartTimeStamp = Get-Date
        $StartTimeStamp = [DateTime]::new($StartTimeStamp.Year, $StartTimeStamp.Month, $StartTimeStamp.Day, $StartTimeStamp.Hour, $StartTimeStamp.Minute, $StartTimeStamp.Second, 0)
    
        $StopMonitoring = $false
        $SampleSize = $NSCollectionInterval
    
        while ($StopMonitoring -eq $false) {
            $CurrentTime = Get-Date
            while ($StartTimeStamp.AddSeconds(60) -gt $CurrentTime) {
                Start-Sleep -Seconds 1
                $CurrentTime = Get-Date
            }
            
            $NSStats = "$($OutputFolder)\NetScaler Raw.csv"
            $NetScalerStats = Invoke-NetScalerStats -HostName $NSIP -Password $NSPassword -UserName $NSUserName
            
            $item = New-Object PSObject  
            $item | Add-Member -MemberType NoteProperty -Name "Timestamp" -Value (Get-Date ($StartTimeStamp.ToUniversalTime()) -Format "o") -Force  
            $item | Add-Member -MemberType NoteProperty -Name "cpuusagepcnt" -Value $NetScalerStats.cpuusagepcnt -Force
            $item | Add-Member -MemberType NoteProperty -Name "pktcpuusagepcnt" -Value $NetScalerStats.pktcpuusagepcnt -Force
            $item | Add-Member -MemberType NoteProperty -Name "mgmtcpuusagepcnt" -Value $NetScalerStats.mgmtcpuusagepcnt -Force
            $item | Add-Member -MemberType NoteProperty -Name "memusagepcnt" -Value $NetScalerStats.memusagepcnt -Force
            $item | Add-Member -MemberType NoteProperty -Name "memuseinmb" -Value $NetScalerStats.memuseinmb -Force
            $item | Add-Member -MemberType NoteProperty -Name "totrxmbits" -Value $NetScalerStats.totrxmbits -Force
            $item | Add-Member -MemberType NoteProperty -Name "rxmbitsrate" -Value $NetScalerStats.rxmbitsrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "tottxmbits" -Value $NetScalerStats.tottxmbits -Force
            $item | Add-Member -MemberType NoteProperty -Name "txmbitsrate" -Value $NetScalerStats.txmbitsrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "httptotrequests" -Value $NetScalerStats.httptotrequests -Force
            $item | Add-Member -MemberType NoteProperty -Name "httprequestsrate" -Value $NetScalerStats.httprequestsrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "httptotresponses" -Value $NetScalerStats.httptotresponses -Force
            $item | Add-Member -MemberType NoteProperty -Name "httpresponsesrate" -Value $NetScalerStats.httpresponsesrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "httptotrxrequestbytes" -Value $NetScalerStats.httptotrxrequestbytes -Force
            $item | Add-Member -MemberType NoteProperty -Name "httprxrequestbytesrate" -Value $NetScalerStats.httprxrequestbytesrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "httptotrxresponsebytes" -Value $NetScalerStats.httptotrxresponsebytes -Force
            $item | Add-Member -MemberType NoteProperty -Name "httprxresponsebytesrate" -Value $NetScalerStats.httprxresponsebytesrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "tcpcurclientconn" -Value $NetScalerStats.tcpcurclientconn -Force
            $item | Add-Member -MemberType NoteProperty -Name "ssltottransactions" -Value $NetScalerStats.ssltottransactions -Force
            $item | Add-Member -MemberType NoteProperty -Name "ssltransactionsrate" -Value $NetScalerStats.ssltransactionsrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "ssltotecdhetransactions" -Value $NetScalerStats.ssltotecdhetransactions -Force
            $item | Add-Member -MemberType NoteProperty -Name "sslecdhetransactionsrate" -Value $NetScalerStats.sslecdhetransactionsrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "tcperrrst" -Value $NetScalerStats.tcperrrst -Force
            $item | Add-Member -MemberType NoteProperty -Name "errdroppedrxpkts" -Value $NetScalerStats.errdroppedrxpkts -Force
            $item | Add-Member -MemberType NoteProperty -Name "errdroppedtxpkts" -Value $NetScalerStats.errdroppedtxpkts -Force
            $item | Add-Member -MemberType NoteProperty -Name "http11requestsrate" -Value $NetScalerStats.http11requestsrate -Force
            $item | Add-Member -MemberType NoteProperty -Name "http11responsesrate" -Value $NetScalerStats.http11responsesrate -Force
            $item | Export-Csv -Path $NSStats -NoTypeInformation -Append
            $StartTimeStamp = $StartTimeStamp.AddSeconds($SampleSize)
            if ((New-TimeSpan -Start $Started -End (Get-Date)).TotalMinutes -ge ($DurationInMinutes)) { $StopMonitoring = $true }
        }
    }

    if ($AsJob.IsPresent) {
        Get-Job -Name NSMonitoringJob -ErrorAction Ignore | Stop-Job
        Get-Job -Name NSMonitoringJob -ErrorAction Ignore | Remove-Job
        return (Start-Job -ScriptBlock $MonitoringScriptBlock -Name NSMonitoringJob -ArgumentList @($DurationInMinutes, $Path, $OutputFolder, $NSIP, $NSUserName, $NSPassword, $NSCollectionInterval))
    }

}