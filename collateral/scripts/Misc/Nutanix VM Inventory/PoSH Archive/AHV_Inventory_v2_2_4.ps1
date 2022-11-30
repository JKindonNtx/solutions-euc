

# Adding PS cmdlets
$loadedsnapins=(Get-PSSnapin -Registered | select name).name
if(!($loadedsnapins.Contains("NutanixCmdletsPSSnapin"))){
   Add-PSSnapin -Name NutanixCmdletsPSSnapin 
}



# Connecting to the Nutanix Cluster
Connect-NTNXCluster -Server 10.68.68.30 -UserName admin -AcceptInvalidSSLCerts

# Fetching data and putting into CSV
$vms = @(get-ntnxvm) 

$FullReport=@()
foreach ($vm in $vms){                        
    $usedspace=0
    if(!($vm.nutanixvirtualdiskuuids.count -le 0)){
        foreach($UUID in $VM.nutanixVirtualDiskUuids){
            $usedspace+=(Get-NTNXVirtualDiskStat -Id $UUID -Metrics controller_user_bytes).values[0]
        }
    }
    if ($usedspace -gt 0){
        $usedspace=[math]::round($usedspace /1gb,0)
    }
    $container= "NA"
    if(!($vm.vdiskFilePaths.count -le 0)){
        $container = $vm.vdiskFilePaths[0].split('/')[1]
    }
    $props=[ordered]@{
        "VM Name" = $vm.vmName
        "Container" = $container
        "Protection Domain" = $vm.protectionDomainName
        "Host Placement" = $vm.hostName
        "Power State" = $vm.powerstate
        "IP Address(es)" = $vm.ipAddresses -join ","
        "vCPUs" = $vm.numVCpus
        "vRAM (GB)" = [math]::round($vm.memoryCapacityInBytes / 1GB,0)
        "Disk Count"  = $vm.nutanixVirtualDiskUuids.count
        "Provisioned Space (GB)" = [math]::round($vm.diskCapacityInBytes / 1GB,0)
        "Used Space (GB)" = $usedspace
    } #End properties
    $Reportobject= New-Object PSObject -Property $props
    $fullreport+=$Reportobject
}


$fullreport | Export-Csv -Path ~\Desktop\NutanixInventory.csv -NoTypeInformation -UseCulture

# Disconnecting from the Nutanix Cluster
Disconnect-NTNXCluster -Servers *
 
