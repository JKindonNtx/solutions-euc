<#
.SYNOPSIS
    This Script will configure a new Cluster with the default values ready for the performance testing to be done
.DESCRIPTION
    This Script will configure a new Cluster with the default values ready for the performance testing to be done
    First it will check for and add a VLAN if its not available
    Second it will check for and add a storage container is it does not exist
    Finally it will check for and upload a Build ISO for MDT is its not available
.NOTES
    There are 2 regions in this script - the details of the regions are:
        - Functions and Variables - this region gathers environment info for the build
        - Configuration - this region configures the cluster ready for use
#>

# Region Functions and Variables
# ====================================================================================================================================================
# Import the Functions and set the Variables used throughout the remainder of the script
# ====================================================================================================================================================

# Define the Variables for the script
$functions = get-childitem -Path "/workspaces/solutions-euc/engineering/lab/build/functions/*.psm1"
$JSONFile = "/workspaces/solutions-euc/engineering/lab/build/ConfigureClusterAHV.json"

# Import all the functions required
foreach($function in $functions){ Write-Host (Get-Date)":Importing - $function." ; import-module $function }

# Read the JSON input file into an object
if($null -eq ($JSON = (Read-JSON -JSONFile $JSONFile))){
    Write-Host (Get-Date) ":Unable to read JSON configuration file, quitting"
    Break 
} else {
    Write-Host (Get-Date) ":JSON configuration file loaded"
}

$OutputFolder = "/workspaces/solutions-euc/engineering/lab/build/"

if (-not (Test-Path $OutputFolder)) { New-Item -ItemType Directory -Path $OutputFolder | Out-Null }

if (-not (Test-Path "$OutputFolder\Configuration.csv")) {
    Set-Content -Path "$OutputFolder\Configuration.csv" -Value "1:l,2:l,3:l"
    }
   
$HostData = Get-NutanixV2 -IP "$($JSON.Cluster.IP)" -Password "$($JSON.Cluster.Password)" -UserName "$($JSON.Cluster.UserName)" -APIpath "hosts"
#$Hostitem = $Hostdata.entities | Where-Object {$_.name -eq $NTNXHost}
write-host $Hostdata
start-sleep 5
Foreach ($Hostitem in $Hostdata.entities) {
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "#Host,,"
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Host,$($Hostitem.Name)"
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Server,$($Hostitem.block_model_name) (BIOS $($Hostitem.bios_version))"
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "CPU,$($Hostitem.num_cpu_sockets) sockets, $($Hostitem.cpu_model)"
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Total Cores,$($Hostitem.num_cpu_cores),$($Hostitem.num_cpu_threads) threads"
$MemGB = [Math]::Round($($Hostitem.memory_capacity_in_bytes / 1GB), 0)
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Memory,$($MemGB)GB,"
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Graphics,$($Hostitem.host_gpus),$($Hostitem.gpu_driver_version)"
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "#General,,"
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "Hypervisor,$($Hostitem.hypervisor_full_name)" 
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "serial,$($Hostitem.serial)" 
Add-Content -Path "$OutputFolder\Configuration.csv" -Value "block_serial,$($Hostitem.block_serial)"

}


#-----------------------------------------------------------------------------------------------------------------------------------------------------
#endregion
