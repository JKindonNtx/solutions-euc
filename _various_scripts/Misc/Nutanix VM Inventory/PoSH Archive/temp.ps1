# Adding PS cmdlets
Add-PSSnapin -Name NutanixCmdletsPSSnapin


# Connecting to the Nutanix node
Connect-NTNXCluster -Server 10.21.210.40 -UserName admin -AcceptInvalidSSLCerts

# Fetching data and putting into Excel
$vms = @(get-ntnxvm) 

foreach ($vm in $vms) {
                      
                       $Storage1 = Get-NTNXVirtualDiskStat -Id $vm.nutanixVirtualDiskUuids[0] -Metrics controller_user_bytes
                       $Storage2 = $Storage1.values -replace '[{}]','' / 1TB
                       # $Storage3 = [math]::truncate($Storage2 / 1GB)
                       # $Storage3 = [math]::truncate($Storage1.values -replace '[{}]','' / 1GB)
                       Write-Host $Storage2
                       }                 