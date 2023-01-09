function Get-NTNXHostinfo {
    ##############################
    #.SYNOPSIS
    #Captures performance data
    ##############################
    Param
    (
        [string]$NTNXHost,
        [string]$OutputFolder
    )

    if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

    if (-not (Test-Path "$OutputFolder\Configuration.csv")) {
        Set-Content -Path "$OutputFolder\Configuration.csv" -Value "1:l,2:l,3:l"
    }
   
    $Clusterinfo = Invoke-PublicApiMethodNTNX -Method "GET" -Path "cluster"
    $HostData = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts"
    $Hostitem = $Hostdata.entities | Where-Object {$_.name -eq $NTNXHost}
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "#Host,,"
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Host,$($Hostitem.Name)"
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Server,$($Hostitem.block_model_name) (BIOS $($Hostitem.bios_version))"
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "CPU,$($Hostitem.num_cpu_sockets) sockets, $($Hostitem.cpu_model)"
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Total Cores,$($Hostitem.num_cpu_cores),$($Hostitem.num_cpu_threads) threads"
    $MemGB = [Math]::Round($($Hostitem.memory_capacity_in_bytes / 1GB), 0)
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Memory,$($MemGB)GB,"
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Graphics,$($Hostitem.host_gpus),$($Hostitem.gpu_driver_version)"
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "#General,,"
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "AOS,$($Clusterinfo.version),$($Clusterinfo.full_version)" 
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Nodes,$($Clusterinfo.num_nodes)" 
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Hypervisor,$($Hostitem.hypervisor_full_name)" 
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "serial,$($Hostitem.serial)" 
    Add-Content -Path "$OutputFolder\Configuration.csv" -Value "block_serial,$($Hostitem.block_serial)"

}