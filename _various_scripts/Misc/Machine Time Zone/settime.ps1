Write-Host "This script will set the VM timezone to the current DCs time zone"

import-module ActiveDirectory
$value = "KBTST"
$VMs =  Get-ADComputer -Filter "Name -Like '*$value*'"
$password = ConvertTo-SecureString "nutanix/4u" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("wsperf\Administrator",$password)

Foreach ($vm in $VMs)
{
$dateTime = Get-Date
Invoke-Command -ComputerName $vm.Name -Credential $cred -ScriptBlock { Set-Date -Date $using:datetime; }
Write-Host "Time set for $Vm.Name"
}