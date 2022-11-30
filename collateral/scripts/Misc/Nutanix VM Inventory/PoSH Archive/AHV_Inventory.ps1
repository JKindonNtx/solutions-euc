# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com


# Adding PS cmldets
Add-PSSnapin -Name NutanixCmdletsPSSnapin


## Steven Potrais - Connecting to the Nutanix node

Connect-NTNXCluster -Server 10.21.210.40 -UserName admin -AcceptInvalidSSLCerts
 
# Connect-NutanixCluster -Server 1.1.1.1 -UserName admin -Password admin -AcceptInvalidSSLCerts

## IB - Create a typed array of Hashtables
[System.Collections.Hashtable[]] $AllVMs = @();
 
## IB - Loop through each returned rackable unit/object
foreach ($AllVMs in Get-NTNXVM) {
    ## IB - Add each enumerated object to the array
    $AllVMs += @{
        "Name" = $AllVMs.vmName;
        "OS" =  $AllVMs.guestOperatingSystem;
        "Memory in GB" = $AllVMs.memoryCapacityInBytes / 1GB;
        "Res. Memory in GB" = $AllVMs.memoryReservedCapacityInBytes /1GB;
        "vCPUs" = $AllVMs.numVCpus;
        "Res. Hz" = $AllVMs.cpuReservedinHz;
        "NICs" = $AllVMs.numNetworkAdapters;
        "vDisk" = $AllVMs.nutanixVirtualDisks;
        "Disk Capacity in GB" = [math]::truncate($AllVMs.diskCapacityInBytes / 1GB);
    };
} # end foreach
 
$Params = $null    
$Params = @{    

  Hashtable = $AllVMs;
    Columns = "Name","OS","Memory in GB","Res. Memory in GB","vCPUs","Res. HZ","NICs","Disk Capacity in GB";
}
# $Table = AddWordTable @Params -NoGridLines;
# FindWordDocumentEnd;
  

  get