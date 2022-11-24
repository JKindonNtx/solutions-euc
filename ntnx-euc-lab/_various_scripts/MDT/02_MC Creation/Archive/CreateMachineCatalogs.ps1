
# kees@nutanix.com
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
     # Citrix Specs
    [Parameter(Mandatory = $true)]
    [Alias('CVAD Controller')] [string] $CVADController
)

$nxPasswordSec = ConvertTo-SecureString $nxPassword -AsPlainText -Force

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

# New Broker Catalog
# Allocation types; Permanent, Random, static
# Persisent User Changes; Discard, OnLocal, OnPVD
# ProvisioningType: MCS, PVS, Manual
# SessionSupport: SingleSession, Multisession

$CatalogName = "KB AHV TEST 1"
$AllocationType = "Random"
$PersistUserChanges = "Discard"

New-BrokerCatalog  -AdminAddress $CVADController -AllocationType $AllocationType -IsRemotePC $False -MinimumFunctionalLevel "L7_9" -Name $CatalogName -PersistUserChanges $PersistUserChanges -ProvisioningType "MCS" -Scope @() -SessionSupport "SingleSession"

# New Account Identity Pool
# NamingSchemeType: Aplhabetic, Numeric
$Domain = $env:USERDNSDOMAIN
$OU = "OU=VSI-test,OU=Computers,OU=CORP,DC=contoso,DC=local"

New-AcctIdentityPool  -AdminAddress $CVADController -AllowUnicode  -Domain $Domain -IdentityPoolName $catalogname -NamingScheme "KB###" -NamingSchemeType "Numeric" -OU $OU -Scope @()

# Sets metadata on the Broker catalog with details of the Identity Pool. This is not essential.
# Set-BrokerCatalogMetadata  -AdminAddress $CVADController  -CatalogId "2" -Name "Citrix_DesktopStudio_IdentityPoolUid" -Value "94624495-1c67-41d4-a986-fd30232a2931"

# Check if the Catalog name is used
Test-ProvSchemeNameAvailable  -AdminAddress $CVADController  -ProvisioningSchemeName @("$CatalogName")

# Creates a provisioning scheme object. This is a template for the machines that are to be created. It specifies the hypervisor, network, storage, memory, number of CPUs to be used etc. 
# It takes parameters from the system already set up, such as the HostingUnit name and the path to the VM snapshot to be used for the machines to be created. 
# This command makes a 'consolidated' copy of the VM snapshot being used and, as a result, the process can take time to complete.


$HostingUnitName = 'KBTest'
# $IdentityPoolName

New-ProvScheme  -AdminAddress $CVADController  -CleanOnBoot -CustomProperties "<CustomProperties xmlns=`"http://schemas.citrix.com/2014/xd/machinecreation`">`r`n  <StringProperty Name=`"ContainerPath`" Value=`"/1265.storage`"/>`r`n  <StringProperty Name=`"vCPU`" Value=`"1`"/>`r`n  <StringProperty Name=`"RAM`" Value=`"2048`"/>`r`n  <StringProperty Name=`"CPUCores`" Value=`"2`"/>`r`n</CustomProperties>" -HostingUnitName $HostingUnitName -IdentityPoolName $CatalogName -InitialBatchSizeHint "4" -MasterImageVM "XDHyp:\HostingUnits\KBTest\W10-1803-VirtIO1.1.4.template" -Metadata @{"NutanixCoresPerCpu"="2";"NutanixContainerId"="1265"} -NetworkMapping @{"0"="XDHyp:\HostingUnits\KBTest\VDI-LAN.network"} -ProvisioningSchemeName $CatalogName -RunAsynchronously -Scope @() -VMCpuCount 1 -VMMemoryMB 2048

# Marker above code works

$ProvTask = Get-ProvTask  -AdminAddress $CVADController  -MaxRecordCount 2147483647

Remove-ProvTask  -AdminAddress $CVADController -TaskId $ProvTask.TaskId.Guid


$ProvScheme = Get-BrokerCatalog -AdminAddress $CVADController -Name $CatalogName

Set-BrokerCatalog  -AdminAddress $CVADController -Name $CatalogName -ProvisioningSchemeId $ProvScheme.ProvisioningSchemeId.guid

Add-ProvSchemeControllerAddress  -AdminAddress $CVADController  -ControllerAddress @("CONTMXD002.contoso.local")" -ProvisioningSchemeName $CatalogName

Get-AcctADAccount  -AdminAddress $CVADController  -IdentityPoolUid "94624495-1c67-41d4-a986-fd30232a2931" -Lock $False -MaxRecordCount 2147483647 -State "Available"

New-AcctADAccount  -AdminAddress $CVADController  -Count 4 -IdentityPoolUid "94624495-1c67-41d4-a986-fd30232a2931""

Get-ProvScheme  -AdminAddress $CVADController  -MaxRecordCount 2147483647 -ProvisioningSchemeName $CatalogName

New-ProvVM  -ADAccountName @("CONTOSO\KB001$","CONTOSO\KB002$","CONTOSO\KB003$","CONTOSO\KB004$") -AdminAddress $CVADController " -ProvisioningSchemeName $CatalogName -RunAsynchronously

Lock-ProvVM  -AdminAddress $CVADController " -ProvisioningSchemeName "KB AHV Test" -Tag "Brokered" -VMID @("61e66a98-ee24-4ec1-be05-cb12847ffa5c","1221e876-38c8-4c1b-a3c2-201ce016d037","d3c07fed-c509-4f57-8c2a-15e4667303e8","2e28fd61-8907-405c-8af1-6f7fd28fd478")

New-BrokerMachine  -AdminAddress $CVADController  -CatalogUid 2 -MachineName "S-1-5-21-2447166850-1907450037-1256696323-71795"

New-BrokerMachine  -AdminAddress $CVADController  -CatalogUid 2 -MachineName "S-1-5-21-2447166850-1907450037-1256696323-71793"

New-BrokerMachine  -AdminAddress $CVADController  -CatalogUid 2 -MachineName "S-1-5-21-2447166850-1907450037-1256696323-71794"

New-BrokerMachine  -AdminAddress $CVADController  -CatalogUid 2 -MachineName "S-1-5-21-2447166850-1907450037-1256696323-71792"

Remove-ProvTask  -AdminAddress $CVADController -TaskId "3b46c10b-a6a0-40a5-820c-4b6d4aabec18"