function Enable-VBS {
    Param(
        [string]$VMName)
 
    Get-Module -Name VMware* -ListAvailable | Import-Module
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm:$false
    Set-PowerCLIConfiguration -DefaultVIServerMode single -Confirm:$false

    #Connect to vCenter server
    $configESXServer = Get-Content -Path "$PSScriptRoot\config.ESXServer.json" -Raw | ConvertFrom-Json
    $VCPassword = ConvertTo-SecureString $($configESXServer.VCPassword) -AsPlainText -Force
    $VCcredentials = New-Object System.Management.Automation.PSCredential ($($configESXServer.UserName), $VCPassword)
    Connect-VIServer -Server $($configESXServer.vSphereServer) -Credential $VCcredentials | Out-Null
    $VM = Get-VM "$VMName"
     $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.Firmware = [VMware.Vim.GuestOsDescriptorFirmwareType]::efi
$spec.NestedHVEnabled = $true
$boot = New-Object VMware.Vim.VirtualMachineBootOptions
$boot.EfiSecureBootEnabled = $true
$spec.BootOptions = $boot
$flags = New-Object VMware.Vim.VirtualMachineFlagInfo
$flags.VbsEnabled = $true
$flags.VvtdEnabled = $true
$spec.flags = $flags
$vm.ExtensionData.ReconfigVM($spec)
    


}      
