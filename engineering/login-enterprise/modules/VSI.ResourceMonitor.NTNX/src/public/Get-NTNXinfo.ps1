function Get-NTNXinfo {
    ##############################
    #.SYNOPSIS
    #Captures Nutanix info
    ##############################
    Param
    (
        [System.Object]$Config
    )
    
    $NTNXHost = $($Config.Target.NTNXHost)
    $Clusterinfo = Invoke-PublicApiMethodNTNX -Method "GET" -Path "cluster"
    $HostData = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts"
    $Hostitem = $Hostdata.entities | Where-Object {$_.name -eq $NTNXHost}
    $Config.Testinfra.HardwareType = $Hostitem.block_model_name
    $config.Testinfra.CPUType = $Hostitem.cpu_model -Replace ("\(R\)","") -Replace ("Intel ","") -Replace ("AMD ","")
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
    $Config.Testinfra.HypervisorVersion = $Hostitem.hypervisor_full_name -Replace ("Nutanix ","") -Replace ("VMware ESXi ","")
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
    $Config.Testinfra.HostGPUs = $Hostitem.host_gpus
    $Config.Testinfra.GPUDriver = $Hostitem.gpu_driver_version
    if ($($Config.Target.NodeCount) -eq 1) {
        $Config.Testinfra.SingleNodeTest = 'true'
        $Config.Testinfra.SetAffinity = 'true'
    } Else {
        $Config.Testinfra.SingleNodeTest = 'false'
        $Config.Testinfra.SetAffinity = 'false'
    }
    $Config
}