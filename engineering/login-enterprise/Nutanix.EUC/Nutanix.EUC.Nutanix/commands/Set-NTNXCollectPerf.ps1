function Set-NTNXCollectPerf {

    [CmdletBinding()]
    
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$ClusterIP,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$CVMSSHPassword,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][ValidateSet("start", "stop")][string]$Action,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][int]$SampleInterval
    )

    # Build the command and set the curator status using SSH
    if ($Action -eq "start") {
        $command = "collect_perf start --sample_seconds $SampleInterval"
    } elseif ($Action -eq "stop") {
        $command = "collect_perf stop"
    }

    $password = ConvertTo-SecureString "$CVMsshpassword" -AsPlainText -Force
    $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)

    # Create the session
    try {
        $session = New-SSHSession -ComputerName $ClusterIP -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -ErrorAction Stop
        $sshStream = New-SSHShellStream -SessionId $session.SessionId -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }

    #Execute the commands
    if ($Action -eq "start") {
        Write-Log -Message "Starting the performance collection (collect_perf)" -Level Info
        $sshStream.WriteLine($command)
        Start-sleep -Seconds 10
        $JobFinished = $false
        while ($JobFinished -eq $false) {
            $JobOutput = $sshStream.Read()
            if ($JobOutput -like "*nutanix@*") {
                $JobFinished = $true
            }
            Write-Log -Message "Waiting 10 seconds for $($Action) job to confirm start" -Level Info 
            Start-sleep -Seconds 10
        }
    } elseif ($Action -eq "stop") {
        #Start a timer to track the time it takes to process the data
        $ColPerfTimer = [System.Diagnostics.Stopwatch]::StartNew()

        $StopAttempt = 1
        Write-Log -Message "Stopping the performance collection (collect_perf)" -Level Info
        $sshStream.WriteLine($command)
        Start-sleep -Seconds 30
        $JobFinished = $false
        while ($JobFinished -eq $false) {
            $JobOutput = $sshStream.Read()
            if ($JobOutput -match "all node collectors have stopped") {
                $JobFinished = $true
            }
            Write-Log -Message "Waiting 30 seconds for $($Action) job to confirm finish. Attempt $($StopAttempt)" -Level Info -Update
            Start-sleep -Seconds 30
            $StopAttempt ++
        }
        # Extract and report the path starting with /home/nutanix
        if ($JobOutput -match "/home/nutanix\S*") {
            $Path = $matches[0]
            if ($JobOutput -match "\d{1,3}(\.\d{1,3}){3}") {
                $SvmExternalIp = $matches[0]
            }
            Write-Log -Message "Collect Perf job has finished. Retrieve the data file from Cluster $($SvmExternalIp) at: $($Path)" -Level Info
        }

        $ColPerfTimer.Stop()
        $ColPerfTimerElapsedTime = [math]::Round($ColPerfTimer.Elapsed.TotalSeconds, 2)
        Write-Log -Message "Collect_perf data processing time: $($ColPerfTimerElapsedTime) seconds" -Level Info
    }

    #Remove the SSH session
    Remove-SSHSession -Name $Session | Out-Null

}