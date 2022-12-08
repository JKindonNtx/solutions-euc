#####################################################################
# Load VMware Plugins and connect to vCenter
#####################################################################
 #Import-Module -Name Vmware*
 Get-Module -Name VMware* -ListAvailable | Import-Module
 Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false
 Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false
 Set-PowerCLIConfiguration -DefaultVIServerMode single -Confirm:$false
 
 $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
 
 #Connect to vCenter server
 $VCPassword = ConvertTo-SecureString $($configESXServer.VCPassword) -AsPlainText -Force
 $VCcredentials = New-Object System.Management.Automation.PSCredential ($($configESXServer.UserName), $VCPassword)
 Connect-VIServer -Server $($configESXServer.vSphereServer) -Credential $VCcredentials | Out-Null 
 
########################################################################
# Add Multiple Hosts to vCenter
######################################################################## 
 
# Variables
## You can use comma separated names or change to pull from a text file. Your pick.
$ESXiHost = "DRMPERF61-1.wsperf.nutanix.com"
## Enter the name of a Data Center or Host Cluster
$ESXiLocation = "VDI1"

## You can use comma separated names or change to pull from a text file. Your pick.
$ESXiHosts = "DRMPERF61-2.wsperf.nutanix.com" , "DRMPERF61-3.wsperf.nutanix.com" , "DRMPERF61-4.wsperf.nutanix.com"
## Enter the name of a Data Center or Host Cluster
$ESXiLocation2 = "VDI2"
 
# Start Script
$ESXiPassword = ConvertTo-SecureString $($configESXServer.rootPassword) -AsPlainText -Force
$ESXicredentials = New-Object System.Management.Automation.PSCredential ("root", $ESXiPassword)
 
Foreach ($ESXiHost in $ESXiHost) { 
 Add-VMHost -Name $ESXiHost -Location $ESXiLocation -User "root" -Password $ESXiPassword -RunAsync -force
 Write-Host -ForegroundColor GREEN "Adding ESXi host $ESXiHost to vCenter"
 } 

 Foreach ($ESXiHosts in $ESXiHosts) { 
    Add-VMHost -Name $ESXiHosts -Location $ESXiLocation2 -User "root" -Password $ESXiPassword -RunAsync -force
    Write-Host -ForegroundColor GREEN "Adding ESXi host $ESXiHosts to vCenter"
    } 
# End Script 