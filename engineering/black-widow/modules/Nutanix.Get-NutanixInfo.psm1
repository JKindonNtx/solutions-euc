function Get-NutanixInfo {
    Param
    (
        [System.Object]$Config
    )
    
    $NTNXHost = $($Config.General.NutanixHost)
    $Clusterinfo = Invoke-PublicApiMethodv2 -Method "GET" -Path "cluster" -UserName $($Config.General.ClusterUserName) -Password $($Config.General.ClusterPassword) -Cvm $($Config.General.ClusterIp)
    $HostData = Invoke-PublicApiMethodv2 -Method "GET" -Path "hosts" -UserName $($Config.General.ClusterUserName) -Password $($Config.General.ClusterPassword) -Cvm $($Config.General.ClusterIp)
    $VMData = Invoke-PublicApiMethodv1 -Method "GET" -Path "vms" -UserName $($Config.General.ClusterUserName) -Password $($Config.General.ClusterPassword) -Cvm $($Config.General.ClusterIp)
    $Hostitem = $Hostdata.entities | Where-Object {$_.name -eq $NTNXHost}
    $Config.Testinfra.HardwareType = $Hostitem.block_model_name
    $config.Testinfra.CPUType = $Hostitem.cpu_model -Replace ("\(R\)","") -Replace ("Intel ","") -Replace ("AMD ","") -Replace ("  ","")
    if ($Hostitem.cpu_model -Like 'Intel*') {
        $Config.Testinfra.CPUBrand = "Intel"
    }
    if ($Hostitem.cpu_model -Like 'AMD*') {
        $Config.Testinfra.CPUBrand = "AMD"
    }
    $Config.Testinfra.clusterName = $Clusterinfo.name
    $Config.Testinfra.AOSVersion = $Clusterinfo.version
    $Config.Testinfra.TotalNodes = $Clusterinfo.num_nodes
    if ($Hostitem.hypervisor_type -eq 'kVMware') {
        $Config.Testinfra.HypervisorBrand = "VMware"
        $Config.Testinfra.HypervisorType = "ESXi"
    }
    if ($Hostitem.hypervisor_type -eq 'kKvm') {
        $Config.Testinfra.HypervisorBrand = "Nutanix"
        $Config.Testinfra.HypervisorType = "AHV"
    }
    $Config.Testinfra.HypervisorVersion = $Hostitem.hypervisor_full_name -Replace ("Nutanix ","") -Replace ("VMware ESXi ","") -Replace ("  ","")
    $Config.Testinfra.CPUSocketCount = $Hostitem.num_cpu_sockets
    $Config.Testinfra.CPUcores = $Hostitem.num_cpu_cores
    $Config.Testinfra.CPUThreadCount = $Hostitem.num_cpu_threads
    $Config.Testinfra.CPUSpeed = [Math]::Round($($Hostitem.cpu_frequency_in_hz / 1000000000),1)
    $Config.Testinfra.MemoryGB = [Math]::Round($($Hostitem.memory_capacity_in_bytes / 1GB), 0)
    $Config.Testinfra.ipmiaddress = $Hostitem.ipmi_address
    $Config.Testinfra.Hostip = $Hostitem.hypervisor_address
    $Config.Testinfra.HostCVMip = $Hostitem.service_vmexternal_ip
    $Config.Testinfra.NodeSerial = $Hostitem.serial
    $Config.Testinfra.BlockSerial = $Hostitem.block_serial
    if ($Hostitem.bios_version -eq $null) {
        $Config.Testinfra.BIOS = "Unknown"
    } Else {
        $Config.Testinfra.BIOS = $Hostitem.bios_version
    }
    $Config.Testinfra.FullVersion = $Clusterinfo.full_version
    if ($Hostitem.host_gpus -eq $null) {
        $Config.Testinfra.HostGPUs = "None"
    } Else {
        $Config.Testinfra.HostGPUs = $Hostitem.host_gpus
    }
    $Config.Testinfra.GPUDriver = $Hostitem.gpu_driver_version
    $NetScaler = $VMData.entities | Where-Object {$_.ipAddresses -like "*$($Config.NetScaler.TargetIP)*" }
    $Config.NetScalerData.vCPU = $NetScaler.numVCpus 
    $Config.NetScalerData.Memory = (($NetScaler.memoryCapacityInBytes / 1024) / 1024)
    $Config
}