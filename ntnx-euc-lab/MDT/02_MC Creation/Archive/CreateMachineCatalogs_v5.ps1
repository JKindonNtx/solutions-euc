﻿# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on March, 2019

# Setting parameters for the connection
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None") ]
 
Param(
    # Nutanix cluster IP address
     [Parameter(Mandatory = $true)]
     [Alias('IP')] [string] $nxIP,   
    # Nutanix cluster username
     [Parameter(Mandatory = $true)]
     [Alias('User')] [string] $nxUser,
    # Nutanix cluster password
     [Parameter(Mandatory = $true)]
     [Alias('Password')] [String] $nxPassword,
     # Citrix CVAD Specs
    [Parameter(Mandatory = $true)]
    [Alias('CVAD Controller')] [string] $CVADController,
    [Parameter(Mandatory = $true)]
    [Alias('Hosting Connection Name')] [string] $ConnectionName,
    [Parameter(Mandatory = $true)]
    [Alias('ResourceName')] [string] $VlanName
)


# Setting parameters for Machine Catalog properties
$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force
$network = $VlanName                                    #Name of the network 
$hostingUnitName = $VlanName                            #Reusing the VLAN Name as ResourceName to avoid multiple connections with the same resource definition

$provSchemeName = "Login VSI automated test"            #Name of the machine catalog that will be created (Name must be unique.)
$domain = "Contoso.local"                               #Domain Name (Domain controller)
$idPoolName = "LoginVSI2"                               #Name of the Identity pool that will be created (Name must be unique.)
$adAccountNameSpecification = "XDMS-###"                #AD machine account naming conventions
$allocType = "Random"                                   #Machine allocation type : Random, Static
$persistChanges = "Discard"                             #Persist Changes : Discard, OnLocal, OnPvd
$sessionSupport = "SingleSession"                       #Session : SingleSession, MultipleSession
$machineCount = 50                                      #Number of machines to be created
$containerID = 1265                                     #Container Id
$vCPU = 1                                               #Number of vCPUs
$RAM = 3072                                             #RAM Size in MB
$storage = "VDI"                                        #Name of the container
# End of Global variables
$connectionCustomProperties = "<CustomProperties></CustomProperties>"
$hostingCustomProperties = "<CustomProperties></CustomProperties>"
$provcustomProperties = @"
<CustomProperties xmlns="http://schemas.citrix.com/2014/xd/machinecreation">
  <StringProperty Name="ContainerPath" Value="$containerID.container"/>
  <StringProperty Name="vCPU" Value="$vCPU"/>
  <StringProperty Name="RAM" Value="$RAM"/>
  <StringProperty Name="CPUCores" Value="$coresPerCPU"/>            
</CustomProperties>
"@
# Setting variables for the hosting connection(s)

$hypRootPath = "xdhyp:\Connections\"+$hypConnName+"\"

 Function write-log {
  <#
   .Synopsis
   Write logs for debugging purposes
   
   .Description
   This function writes logs based on the message including a time stamp for debugging purposes.
  #>
  param (
  $message,
  $sev = "INFO"
  )
  if ($sev -eq "INFO"){
  write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
  } elseif ($sev -eq "WARN"){
  write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
  } elseif ($sev -eq "ERROR"){
  write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
  } elseif ($sev -eq "CHAPTER"){
  write-host "`n`n### $message`n`n"
  }
} 

# Adding PS cmdlets for Citrix
$loadedsnapins=(Get-PSSnapin -Registered | Select-Object name).name
if(!($loadedsnapins.Contains("Citrix"))){
 Add-PSSnapin -Name Citrix* 
 write-log -message "Citrix cmdlets are loaded, commencing the script"
}

if ($null -eq (Get-PSSnapin -Name Citrix* -ErrorAction SilentlyContinue))
{
  write-log -message "Citrix cmdlets are not loaded, aborting the script"
  break
}

# Setting up the hosting connection

$ExistinghostingConnection = Test-Path -EA Stop -Path @("XDHyp:\Connections\$ConnectionName") -AdminAddress $CVADController
write-log -message "Checking if the hosting connection already exists"

if ($ExistinghostingConnection -eq $False){
                                           $Connectionuid = New-Item -ConnectionType "Custom" -CustomProperties "" -HypervisorAddress @("$nxIP") -Path @("XDHyp:\Connections\$ConnectionName") -PluginId "AcropolisFactory" -Scope @() -SecurePassword $nxPasswordSec -UserName $nxUser -persist | select HypervisorConnectionUid
                                           New-BrokerHypervisorConnection -AdminAddress $CVADController -HypHypervisorConnectionUid $connectionuid.HypervisorConnectionUid | Out-Null
                                           write-log -message "Creating the hosting connection $ConnectionName"

                                           # Create Resources 'NTNX-LAN'  

                                            Set-HypAdminConnection  -AdminAddress $CVADController

                                            $ExistinghostingResource = Test-Path -EA Stop -Path @("XDHyp:\HostingUnits\$VlanName") -AdminAddress $CVADController

                                            if ($ExistinghostingResource -eq $False){
                                                                                       New-Item -HypervisorConnectionName $ConnectionName -NetworkPath @("XDHyp:\Connections\$ConnectionName\VDI-LAN.network") -Path @("XDHyp:\HostingUnits\$VlanName") -PersonalvDiskStoragePath @() -RootPath "XDHyp:\Connections\$ConnectionName" -StoragePath @() | Out-Null
                                                                                       write-log -message "Creating the resources $VlanName for $ConnectionName"
                                                                                    }
                                            Else {
                                                    Write-log -message "This VLAN is already assigned as a resource to the hosting connection, terminating the script"
                                                    break
                                                    }
                                        }
Else {
        write-log -message "This hosting connection already exists"
        }
 
$hypHc = get-Item -Path xdhyp:\Connections\$ConnectionName 
# Create the AdIdentity Pool 
Try{
$adAccountPool = New-AcctIdentityPool -IdentityPoolName $idPoolName -NamingScheme $adAccountNameSpecification -NamingSchemeType Numeric -Domain $domain -OU $adContainerDN
# Create the Provisioning Scheme
Try{
$provScheme = New-ProvScheme -ProvisioningSchemeName $provSchemeName -HostingUnitName $hostingUnitName -MasterImageVM $baseImagePath -IdentityPoolName $idPoolName -CleanOnBoot -NetworkMapping $networkMap -CustomProperties $provcustomProperties
 }
 Catch{
 write-log -message "Unable to create the prov scheme"
 break
 }

# Create the AD accounts and VMs
Try{
$adAccounts = New-AcctADAccount -IdentityPoolName $idPoolName -Count $machineCount
$vms = New-ProvVm -ProvisioningSchemeName $provSchemeName -ADAccountName $adAccounts.SuccessfulAccounts 
# Integrate With Broker
$provScheme = Get-ProvScheme -ProvisioningSchemeName $provSchemeName
$bhc = get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid
# Wait for the broker’s hypervisor connection to be ready before trying to use it.
while (-not $bhc.IsReady)
{
    Start-Sleep –s 5
    $bhc = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hypHc.HypervisorConnectionUid
}
# Create a new Machine Catalog
Try{
# Clone the VMs and make sure they're available under the machine catalog
$machineCreatedCount = 0
foreach ($provVm in $vms.CreatedVirtualMachines)
{
    $bpm = New-BrokerMachine -CatalogUid $bdc.Uid -HypervisorConnectionUid $bhc.Uid -HostedMachineId $provVm.VMId -MachineName $provVm.AdAccountSid
    $machineCreatedCount++
}
if($machineCreatedCount -gt 0)
{
    write-log -message "Setup and Machine Catalog creation completed successfully"
}