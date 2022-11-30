

# Adding PS cmdlets
Add-PSSnapin -Name NutanixCmdletsPSSnapin


# Connecting to the Nutanix node
Connect-NTNXCluster -Server 10.68.68.30 -UserName admin -AcceptInvalidSSLCerts

# Fetching data and putting into CSV
$vms = @(get-ntnxvm) 

$FullReport=@()
foreach ($vm in $vms){
                        $usedspace=0
                        if(!($vm.nutanixvirtualdiskuuids.count -le 0)){
                            $usedspace = [math]::round($(Get-NTNXVirtualDiskStat -Id $vm.nutanixVirtualDiskUuids[0] -Metrics controller_user_bytes).values[0],0)
                        }
                        
                        $container= "NA"
                        if(!($vm.vdiskFilePaths.count -le 0)){
                            $container = $vm.vdiskFilePaths[0].split('/')[1]
                        }

                       $diskcollection=0
                        foreach($UUID in $vms.nutanixVirtualDiskUuids){
                        $size= [math]::round($(Get-NTNXVirtualDiskStat -Id $uuid -Metrics controller_user_bytes).values[0],0)
                        $diskcollection+=$size
 }
 }

                        $Reportobject= New-Object PSObject -Property @{
                        "VM Name" = $vm.vmName
                        "Container" = $container
                        "Protection Domain" = $vm.protectionDomainName
                        "Host Placement" = $vm.hostName
                        "Power State" = $vm.powerstate
                        "IP Address(es)" = $vm.ipAddresses -join ","
                        "vCPUs" = $vm.numVCpus
                        "vRAM" = [math]::round($vm.memoryCapacityInBytes / 1GB,0)
                        "Provisioned Space in GB" = [math]::round($vm.diskCapacityInBytes / 1GB,0)
                        "Used Space" = [math]::round($usedspace / 1GB,0)
                        "Actual Used Space" = [math]::round($diskcollection / 1GB,0)
             } #End Object
             $fullreport+=$Reportobject

   





$fullreport | Export-Csv -Path ~\Desktop\NutanixInventory.csv -NoTypeInformation -UseCulture
