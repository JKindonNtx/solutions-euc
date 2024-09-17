function Set-CVMObserver {
    param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][System.Object]$Config,
        [Parameter(Mandatory = $false)][System.Collections.ArrayList]$CVMIPs,
        [Parameter(Mandatory = $false)][System.Collections.ArrayList]$HostIPs,
        [Parameter(Mandatory = $true)][String]$prometheusip,
        [Parameter(Mandatory = $true)][String]$prometheussshuser,
        [Parameter(Mandatory = $true)][String]$prometheussshpassword,
        [Parameter(Mandatory = $false)][String]$CVMsshUser,
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][ValidateSet("Start","Stop")]$Status
    )

    $OutputFile = "$env:LOCALAPPDATA\SolutionsEngineering\prometheus.yml"
    if (Test-Path $OutputFile) { Remove-Item -Path $OutputFile -Force }
    
    if ($Status -eq "Stop") {
        $prometheusconfig = @"
global:

  scrape_interval: 30s
  scrape_timeout: 15s

scrape_configs:

"@
   }
    elseif ($Status -eq "Start") {
        $prometheusconfig = @"
global:

  scrape_interval: 30s
  scrape_timeout: 15s

scrape_configs:

"@

if ($Config.Test.StartObserverMonitoring -eq $true) {
    $prometheusconfig += @"
  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_$($CVMIPs[0])_shell_hostssh_ipmitool_dcmi_power_reading_onetime
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$($CVMIPs[0])']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['hostssh ipmitool dcmi power reading']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']


"@
foreach ($ip in $CVMIPs) {
    $prometheusconfig += @"
  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_shell_iostat
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['iostat -x -m -y 3 1']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_shell_nstat_a
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['nstat -a']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_shell_sys_class_net_statistics
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['sys -class net_statistics']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_links_dump_2009_stargate
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['links_dump']
            Observer_user_input_command: ['http:0:2009']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_links_dump_2009_stargate_oplog_disk_stats
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['links_dump']
            Observer_user_input_command: ['http:0:2009/oplog_disk_stats']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_links_dump_2009_stargate_oplog_flush_stats
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['links_dump']
            Observer_user_input_command: ['http:0:2009/oplog_flush_stats']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_shell_mpstat_A_all
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['mpstat -A 5 1']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_shell_stargate_top
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['export TERM=xterm-256color;cd /tmp;echo "top -b -w 200 -n 1 -H -p ``pgrep -d "," stargate``" > stargate_top.obs.tmp;cat stargate_top.obs.tmp;source stargate_top.obs.tmp']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']

  - job_name: Observer_$($Config.TestInfra.clustername)_CVM_${ip}_shell_ifconfig_eth0_ifconfig_eth1
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['CVM']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['$($CVMsshUser)']
            Observer_user_input_password: ['$($Config.Target.CVMsshpassword)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['ifconfig eth0;ifconfig eth1']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']


"@
}
foreach ($ip in $HostIPs) {
  if ($Config.TestInfra.HostGPUs -ne "None"){
  $prometheusconfig += @"
  - job_name: Observer_$($Config.TestInfra.clustername)_AHV_${ip}_shell_nvidia_smi
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['AHV']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['root']
            Observer_user_input_password: ['$($Config.Target.Host_root_password)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['nvidia-smi -q']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']


"@
  }
  if ($Config.Target.HypervisorType -eq "AHV") {
  $prometheusconfig += @"
  - job_name: Observer_$($Config.TestInfra.clustername)_AHV_${ip}_shell_cpupower_monitor
    metrics_path: /nutanix-observer/Observer_INPUT_PARSER/Observer_INPUT_PARSER.sh
    scrape_interval: 30s
    static_configs:
      - targets: ['$($prometheusip):80']
    params:
            Observer_user_input_action: ['Nutanix_Observer_Collect_Metric']
            Observer_user_input_command_target_type: ['AHV']
            Observer_user_input_target_ip_address: ['$ip']
            Observer_user_input_target_user_id: ['root']
            Observer_user_input_password: ['$($Config.Target.Host_root_password)']
            Observer_user_input_command_type: ['shell']
            Observer_user_input_command: ['cpupower monitor']
            Observer_user_input_target_cluster_name: ['$($Config.TestInfra.clustername)']
            Observer_user_input_remote_command_execution_type: ['sshpass']


"@
  }
} 
}
if ($Config.Target.files_prometheus -eq $true) {
  foreach ($ip in $Config.Target.files_ips) {
      $prometheusconfig += @"
  - job_name: $($Config.Target.files_name)-$ip
    scrape_interval: 10s
    static_configs:
      - targets: ['$($ip):7524', '$($ip):7525']
        labels:
          fs_name: "$($Config.Target.files_name)"
          fs_uuid: "$($Config.Target.files_uuid)"


"@
}   
}
}    
  $prometheusconfig | Out-File -FilePath "$OutputFile"


  Write-Log -Message "Copy prometheus.yml to $prometheusip." -Level Info
  try {
      # Copy the prometheus.yml to the prometheus server and reload prometheus
      $password = ConvertTo-SecureString "$prometheussshpassword" -AsPlainText -Force
      $HostCredential = New-Object System.Management.Automation.PSCredential ($prometheussshuser, $password)
      $session = New-SSHSession -ComputerName $prometheusip -Credential $HostCredential -AcceptKey -KeepAliveInterval 5 -ErrorAction Stop
      Set-SCPItem -ComputerName $prometheusip -Credential $HostCredential -Path $OutputFile -Destination "/etc/prometheus/" -Force
      Invoke-RestMethod -Uri "http://$($prometheusip):9090/-/reload" -Method POST -ErrorAction Stop
  }
  catch {
      Write-Log -Message $_ -Level Warn
      Break
  }

  Remove-SSHSession -Name $Session | Out-Null
  Remove-Item -Path $OutputFile -Force
  Write-Log -Message "Copy and reset prometheus $prometheusip finished. Status is $Status." -Level Info
                   
}