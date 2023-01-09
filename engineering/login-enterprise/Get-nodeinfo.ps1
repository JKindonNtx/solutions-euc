
$OutputFolder = "D:\Hosts"
$ClustersCSV = "D:\Hosts\clusters.csv"
$HostsCSV = "D:\Hosts\Hostnames.csv"

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }
Import-Module $ScriptRoot\modules\VSI.ResourceMonitor.NTNX -Force

$clusters = Import-CSV -Path $ClustersCSV
Foreach ($cluster in $clusters) {
    $VSI_Target_CVM = $cluster.ip
    write-host $cluster.ip
    $hostnames = Import-CSV -Path $HostsCSV
    Foreach ($hostname in $hostnames) {
    Get-NTNXHostinfo -NTNXHost $hostname.hostnames -OutputFolder $OutputFolder
    }
}
       
