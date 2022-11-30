

# Adding PS cmldets
Add-PSSnapin -Name NutanixCmdletsPSSnapin


## Steven Potrais - Connecting to the Nutanix node

Connect-NTNXCluster -Server 10.21.210.40 -UserName admin -AcceptInvalidSSLCerts



$vms = @(get-ntnxvm) 
 
foreach ($vm in $vms) {
                                             New-Object -TypeName PSCustomObject -Property @{
                        VMName = $vm.vmName
                        # UsedSpace = $vm.usedspacegb
                        ProvisionedSpace = [math]::truncate($vm.diskCapacityInBytes / 1GB)
                        Containers = $vm.vdiskFilePaths.split('/')[1]
                        vCPUs = $vm.numVCpus
                        RAM = [math]::truncate($vm.memoryCapacityInBytes / 1GB)
                        PowerState = $vm.powerstate
                        IPAddress = $vm.ipAddresses -join ","
                        ProtectionDomain = $vm.protectionDomainName
                        HostPlacement = $vm.hostName

             } | Export-Csv -Path ~\Desktop\vms.csv -NoTypeInformation -Append
}



# $vms = @(get-vm -Location $mydatacenter) 
 
# foreach ($vm in $vms) {
#                                             New-Object -TypeName PSCustomObject -Property @{
#                        VMName = $vm.name
#                        UsedSpace = $vm.usedspacegb
#                        ProvisionedSpace = $vm.provisionedSpacegb
#                        Description = $vm.description
#                        Datastore = $vm.datastoreidlist
#             } | Export-Csv -Path c:\temp\vms.csv -NoTypeInformation -Append
#}