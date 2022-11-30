

# Adding PS cmdlets
Add-PSSnapin -Name NutanixCmdletsPSSnapin


# Connecting to the Nutanix node
Connect-NTNXCluster -Server 10.21.210.40 -UserName admin -AcceptInvalidSSLCerts

# Fetching data and putting into Excel
$vms = @(get-ntnxvm) 
 
foreach ($vm in $vms) {
                                             [pscustomobject] @{
                        "VM Name" = $vm.vmName
                        # UsedSpace = $vm.usedspacegb
                        "Container" = $vm.vdiskFilePaths.split('/')[1]
                        # "Container" = $vm.vdiskFilePaths -join ""
                        "Protection Domain" = $vm.protectionDomainName
                        "Host Placement" = $vm.hostName
                        "Power State" = $vm.powerstate
                        "IP Address(es)" = $vm.ipAddresses -join ","
                        "vCPUs" = $vm.numVCpus
                        "vRAM" = [math]::truncate($vm.memoryCapacityInBytes / 1GB)
                        "Provisioned Space in GB" = [math]::truncate($vm.diskCapacityInBytes / 1GB)
             } | Export-Csv -Path ~\Desktop\vms2.csv -NoTypeInformation -Append -UseCulture
}

# Get-NTNXVirtualDiskStat -Id -Metrics controller_user_bytes