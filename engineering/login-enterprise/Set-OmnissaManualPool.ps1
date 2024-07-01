#region Variables
# ============================================================================
# Variables
# ============================================================================

# Nutanix CVM Variables
$TargetCVM = "10.56.68.127"
$TargetCVMAdmin = "davidbrett"
$TargetCVMPassword = "Nutanix/4u$"

# Microsoft Active Directory Variables
$var_AD_User = "administrator"
$var_AD_Admin = "administrator"
$var_Admin_Password = "nutanix/4u"
$var_LDAPServer = "10.57.64.20"
$var_Base_DN = "dc=wsperf,dc=nutanix,dc=com"
$var_NetBios_Domain = "wsperf"
$var_Omnissa_Group = "VSILE3"
$Slack = "https://hooks.slack.com/services/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"

# Omnissa Variables
$var_Naming_Convention = "W10-OMN-####"
$var_OU = "OU=Omnissa,OU=Target,OU=Computers,OU=LoginEnterprise,DC=wsperf,DC=nutanix,DC=com"
$var_Omnissa_Base_Vm_Name = "Omnissa_Base_VM"
$var_Number_Of_Vms = 20
$var_Ansible_Path = "/workspaces/solutions-euc/engineering/login-enterprise/ansible/"
$var_Omnissa_Pool_Name = "W10-OMN-MANUAL"
$var_Domain = "wsperf.nutanix.com"
#$var_OS_Type = "WINDOWS_10"
$var_Api_Endpoint = "https://10.57.64.71"
$var_UserName = "Dave"
$var_Password = "Nutanix/4u$"

#endregion Variables

#region Variables
# ============================================================================
# Variables
# ============================================================================

If ([string]::IsNullOrEmpty($PSScriptRoot)) { $ScriptRoot = $PWD.Path } else { $ScriptRoot = $PSScriptRoot }

#endregion Variables

#Region Execute
# ============================================================================
# Execute
# ============================================================================

#region Nutanix Module Import
#----------------------------------------------------------------------------------------------------------------------------
$var_ModuleName = "Nutanix.EUC"
Write-Host "$([char]0x1b)[96m[$([char]0x1b)[97m$(Get-Date)$([char]0x1b)[96m]$([char]0x1b)[97m INFO: Trying to import $var_ModuleName module"
try {
    Import-Module "$ScriptRoot\$var_ModuleName\$var_ModuleName.psd1" -Force -ErrorAction Stop
    Write-Log -Message "Successfully imported $var_ModuleName Module" -Level Info
}
catch {
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: Failed to import $var_ModuleName module. Exit script"
    Write-Host "$([char]0x1b)[31m[$([char]0x1b)[31m$(Get-Date)$([char]0x1b)[31m]$([char]0x1b)[31m ERROR: $_"
    Exit 1
}
#endregion Nutanix Module Import

# Check for Ansible

#endregion variable setting

$Filter = $var_Naming_Convention.Replace("#","")
$CurrentVmsUnsorted = Get-ADComputers -filter $Filter -UserName "$($var_NetBios_Domain)\$var_AD_User" -Password $var_Admin_Password -LDAPServer $var_LDAPServer -BaseDN $var_Base_DN
$CurrentVms = $CurrentVmsUnsorted | Sort-Object

if($null -eq $CurrentVmsUnsorted){
    $var_Start_Index = "1"
} else {
    $var_Start_Index = Get-NextComputerNumber -CurrentVMs $CurrentVMs -NamingConvention $var_Naming_Convention
}

Write-Log -Message "Updating Slack" -Level Info
$SlackMessage = "New AHV Omnissa Manual Pool Creation started by $TargetCVMAdmin on Cluster $($TargetCVM)."
Update-VSISlack -Message $SlackMessage -Slack $Slack


$var_Deployed_VMs = Set-OmnissaVMsAhv -BaseVM $var_Omnissa_Base_Vm_Name -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -NumberOfVMs $var_Number_Of_Vms -NamingConvention $var_Naming_Convention -StartIndex $var_Start_Index -Domain $var_Domain -AdminUserName $var_AD_Admin -AdminPassword $var_Admin_Password -OU $var_OU -RootPath $var_Ansible_Path

$CurrentVmsUnsorted = Get-ADComputers -filter $Filter -UserName "$($var_NetBios_Domain)\$var_AD_User" -Password $var_Admin_Password -LDAPServer $var_LDAPServer -BaseDN $var_Base_DN
$CurrentVms = $CurrentVmsUnsorted | Sort-Object

# Validate this code
$i = 1
foreach($VM in $CurrentVms){
    Write-Log -Update -Message "Removing CD-ROM $($i) of $($var_Number_Of_Vms)." -Level Info
    $vmUUID = (Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq $VM }).uuid
    $Result = Remove-NutanixCDROM -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -VmUuid $vmUUID
    $i++
}

# Create Desktop Pool etc
$Pool = New-OmnissaManualPool -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolName $var_Omnissa_Pool_Name

$CreatedPool = Get-OmnissaDesktopPools -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolName $var_Omnissa_Pool_Name
$Machines = Get-OmnissaPhysicalMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -MachineNaming $Filter

$machinesToAdd = New-Object System.Collections.Generic.List[System.Object]

foreach ($machine in $machines){
    $machinesToAdd.Add($machine.id)
}

$machinesToAddPayload = $machinesToAdd | ConvertTo-Json
$addingMachines = Set-OmnissaManualPoolMachines -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $CreatedPool.id -Payload $machinesToAddPayload

$OmnissaGroup = Get-OmnissaGroupSID -GroupName $var_Omnissa_Group -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain

$Entitlement = Set-OmnissaManualPoolEntitlement -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_Domain -PoolID $CreatedPool.id -GroupID $OmnissaGroup.id

Write-Log -Message "Updating Slack" -Level Info
$SlackMessage = "AHV Omnissa Manual Pool Created`r
Pool Name: $($var_Omnissa_Pool_Name)`r
Number of VMs: $($var_Number_Of_Vms)`r
VM Naming Convention: $($var_Naming_Convention)"
Update-VSISlack -Message $SlackMessage -Slack $Slack