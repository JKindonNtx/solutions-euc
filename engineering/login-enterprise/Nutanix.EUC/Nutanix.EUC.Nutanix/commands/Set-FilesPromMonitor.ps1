Function Set-FilesPromMonitor {

    [CmdletBinding()]

    param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.Object]$Config,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][ValidateSet("Start","Stop")]$Status
    )
    
    
    Write-Log -Message "Enable prometheus monitoring on Files cluster $($Config.Target.files_name)." -Level Info
    try {
        # Build the command and set affinity using SSH
        if ($Status -eq "Stop") {
            $command = "~/minerva/bin/edit-afs-gflags minerva_nvm minerva_files_metrics_enabled False"
        }
        elseif ($Status -eq "Start") {
            $command = "~/minerva/bin/edit-afs-gflags minerva_nvm minerva_files_metrics_enabled True"
        }
        $password = ConvertTo-SecureString $($Config.Target.Files_sshpassword) -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ($($Config.Target.Files_sshuser), $password)
        $session = New-SSHSession -ComputerName $($Config.Target.files_ips[0]) -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -ErrorAction Stop
        $sshStream = New-SSHShellStream -SessionId $session.SessionId
        $sshStream.WriteLine($command)
        $streamOut = $sshstream.Read()
        while ($streamOut -notlike "*FSVM:~$ ") {
            Start-Sleep -s 10
            $streamOut = $sshstream.Read()
        }
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Break
    }

    Remove-SSHSession -Name $Session | Out-Null
    Write-Log -Message "Set Files Monitoring to $($Status)" -Level Info

    $FilePromMonitoringProcessed = $true
        


    return $FilePromMonitoringProcessed #Check this
}