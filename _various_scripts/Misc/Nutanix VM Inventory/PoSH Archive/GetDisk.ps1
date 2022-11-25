# Adding PS cmdlets
Add-PSSnapin -Name NutanixCmdletsPSSnapin


# Connecting to the Nutanix node
Connect-NTNXCluster -Server 10.68.68.30 -UserName admin -AcceptInvalidSSLCerts

# Fetching data and putting into CSV
$vms = @(get-ntnxvm) 

$diskcollection=0
 foreach($vm in $vms){
    foreach($UUID in $vms.nutanixVirtualDiskUuids){
                        $size= [math]::round($(Get-NTNXVirtualDiskStat -Id $uuid -Metrics controller_user_bytes).values[0],0)
                        $diskcollection+=$size
 }
 }

