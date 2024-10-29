function Set-NTNXCollectPerf {

    [CmdletBinding()]
    
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$ClusterIP,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$CVMSSHPassword,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][ValidateSet("start", "stop")][string]$Action,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][int]$SampleInterval = 60,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][int]$SampleFrequency = 5,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$AdvancedArgs,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][string]$OutputFolder,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true )][bool]$DownloadCollectorFile
    )

    # Build the command and set the curator status using SSH
    if ($Action -eq "start") {
        if ($AdvancedArgs) {
            $command = "collect_perf --sample_seconds=$SampleInterval --sample_frequency=$SampleFrequency $AdvancedArgs start"
        } else {
            $command = "collect_perf --sample_seconds=$SampleInterval --sample_frequency=$SampleFrequency start"
        }
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
    }
    elseif ($Action -eq "stop") {
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
                # Extract and report the path starting with /home/nutanix
                $DataFilePath = $JobOutput | Select-String -Pattern "/home/nutanix\S*" | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value  
            }
            Write-Log -Message "Waiting 30 seconds for $($Action) job to confirm finish. Attempt $($StopAttempt)" -Level Info -Update
            Start-sleep -Seconds 30
            $StopAttempt ++
        }
        Write-Log -Message "Collect_perf data file is: $($DataFilePath)" -Level Info

        $ColPerfTimer.Stop()
        $ColPerfTimerElapsedTime = [math]::Round($ColPerfTimer.Elapsed.TotalSeconds, 2)
        Write-Log -Message "Collect_perf data processing time: $($ColPerfTimerElapsedTime) seconds" -Level Info

        if ($DownloadCollectorFile -eq $true) {
            # Download the file using Receive-WinSCPItem. Must use the 6.3.2.0 version of the WinSCP module - nothing newer
            Write-Log -Message "Downloading the data file from CVM $($ClusterIP) to results folder" -Level Info
            try {
                $requiredVersion = [version]"6.3.2.0"

                Import-Module -Name WinSCP -RequiredVersion $requiredVersion -Force -ErrorAction Stop
                $SessionOption = New-WinSCPSessionOption -HostName $ClusterIP -Credential $HostCredential -Protocol Scp -GiveUpSecurityAndAcceptAnySshHostKey
                $SCPSession = New-WinSCPSession -SessionOption $SessionOption -ErrorAction Stop
                $DownloadFile = Receive-WinSCPItem -WinSCPSession $SCPSession -path $DataFilePath -Destination $OutputFolder -ErrorAction Stop

                if ($DownloadFile.IsSuccess -eq $true) {
                    Write-Log -Message "Data file successfully downloaded to: $($OutputFolder)" -Level Info
                } else {
                    Write-Log -Message "Data file failed to download. Retrieve the data file from $($ClusterIP) at: $($DataFilePath)" -Level Warn
                }
                Close-WinSCPSession -WinSCPSession $SCPSession
            
            }
            catch {
                Write-Log -Message "Data file failed to download. Retrieve the data file from $($ClusterIP) at: $($DataFilePath)" -Level Warn
                Write-Log -Message $_ -Level Warn
            }
        } else {
            Write-Log -Message "Collect_perf job has finished. Retrieve the data file from $($ClusterIP) at: $($DataFilePath)" -Level Info
        }
    }

    #Remove the SSH session
    Remove-SSHSession -Name $Session | Out-Null

}