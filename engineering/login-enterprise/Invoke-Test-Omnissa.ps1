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

$var_Omnissa_Base_Vm_Name = "W10-22H2-cab3"
$TargetCVM = "10.56.68.127"
$TargetCVMAdmin = "davidbrett"
$TargetCVMPassword = "Nutanix/4u$"
$var_Number_Of_Vms = 5
$var_Naming_Convention = "W10-OMN-####"
$var_Domain = "wsperf.nutanix.com"
$var_Admin_Password = "nutanix/4u"
$var_OU = "OU=Omnissa,OU=Target,OU=Computers,OU=LoginEnterprise,DC=wsperf,DC=nutanix,DC=com"
$var_Ansible_Path = "C:\Users\dave\Documents\GitHub\solutions-euc\engineering\login-enterprise\ansible\"
$var_OS_Type = "WINDOWS_10"

$CurrentVms = Get-ADComputers -filter $Filter
$var_Start_Index = Get-NextComputerNumber -CurrentVMs $CurrentVMs

$var_Deployed_VMs = Set-OmnissaVMsAhv -BaseVM $var_Omnissa_Base_Vm_Name -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -NumberOfVMs $var_Number_Of_Vms -NamingConvention $var_Naming_Convention -StartIndex $var_Start_Index -Domain $var_Domain -AdminPassword $var_Admin_Password -OU $var_OU -RootPath $var_Ansible_Path

# Unmount CD ROM from VMs

$var_Api_Endpoint = "https://10.57.64.71"
$var_UserName = "Dave"
$var_Password = "Nutanix/4u$"
$var_NetBios_Domain = "wsperf"

foreach($var_VM in $var_Deployed_VMs){
    if(!$null -eq $var_VM.Name){
    $var_FQDN = $var_VM.name + "." + $var_Domain
    $var_Registration = Set-OmnissaRegistration -ApiEndpoint $var_Api_Endpoint -UserName $var_UserName -Password $var_Password -Domain $var_NetBios_Domain -VmDnsName $var_FQDN -VmOperatingSystem $var_OS_Type
    }

}


