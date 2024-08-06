function Start-CVMObserver {
    param(
        [Parameter(Mandatory = $true)][String]$clustername,
        [Parameter(Mandatory = $true)][Array]$CVMIPs,
        [Parameter(Mandatory = $true)][String]$prometheusip,
        [Parameter(Mandatory = $true)][String]$CVMsshUser,
        [Parameter(Mandatory = $true)][String]$CVMsshpassword,
        [Parameter(Mandatory = $true)] [string]$OutputFolder
    )


        if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }
    
        $config = @"
global:

  scrape_interval: 30s
  scrape_timeout: 15s

scrape_configs:

"@
        
foreach ($ip in $CVMIPs) {
    $config += @"
  - job_name: Observer_$($clustername)_CVM_${ip}_links_dump_2009_stargate
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 20s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($CVMsshpassword)']
            Observer_user_input_command_type: ['links_dump']
            Observer_user_input_command: ['http:0:2009']
            Observer_user_input_target_cluster_name: ['$($clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($clustername)_CVM_${ip}_links_dump_2009_stargate_oplog_disk_stats
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($CVMsshpassword)']
            Observer_user_input_command_type: ['links_dump']
            Observer_user_input_command: ['http:0:2009/oplog_disk_stats']
            Observer_user_input_target_cluster_name: ['$($clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($clustername)_CVM_${ip}_links_dump_2009_stargate_oplog_flush_stats
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($CVMsshpassword)']
            Observer_user_input_command_type: ['links_dump']
            Observer_user_input_command: ['http:0:2009/oplog_flush_stats']
            Observer_user_input_target_cluster_name: ['$($clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($clustername)_CVM_${ip}_shell_mpstat_A_all
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['mpstat -A 5 1']
            Observer_user_input_target_cluster_name: ['$($clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']


"@
    }
        
    $config | Out-File -FilePath "$OutputFolder\prometheus.yml"

    Write-Log -Message "Copy prometheus.yml to $prometheusip." -Level Info
    try {
        # Copy the prometheus.yml to the prometheus server and reload prometheus
        $password = ConvertTo-SecureString "nutanix/4u" -AsPlainText -Force
        $HostCredential = New-Object System.Management.Automation.PSCredential ("nutanix", $password)
        $session = New-SSHSession -ComputerName $prometheusip -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -ErrorAction Stop
        Set-SCPItem -ComputerName $prometheusip -Credential $HostCredential -Path "$OutputFolder\prometheus.yml" -Destination "/etc/prometheus/" -Verbose -AcceptKey
        #Copy-SCPFile -Session $Session -RemotePath "/etc/prometheus/" -LocalPath "$OutputFolder\prometheus.yml" -Confirm:$false
        Invoke-RestMethod -Uri "http://$($prometheusip):9090/-/reload" -Method POST
    }
    catch {
        Write-Log -Message $_ -Level Warn
        Break
    }

    Remove-SSHSession -Name $Session | Out-Null
    Write-Log -Message "Copy and reset prometheus $prometheusip finished." -Level Info
                   
}