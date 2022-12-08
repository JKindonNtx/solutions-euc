    #Import Nutanix Module
    & "${env:ProgramFiles(x86)}\Nutanix Inc\NutanixCmdlets\powershell\import_modules\ImportModules.PS1"
Connect-NutanixCluster -Server 10.56.4.40 -UserName admin -AcceptInvalidSSLCerts
$desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"}
$totalDesktops = $desktops.Count
$desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'On'}
$desktopsOn = @()
foreach ($desktop in $desktops) { 
    $vm = $desktop.vmName
    $desktopsOn += $vm
}
Write-Host (Get-Date) ": $($DesktopsOn.count) desktops are powered on."
# Shutdown Frame VMs
if ($desktopsOn.Count -ne 0) {
    Write-Host (Get-Date) ": Shutdown $($desktopsOn.count) VMs."
    foreach ($desktop in $desktops) {
        $vmId = ($desktop.vmid.split(":"))[2]
        Set-NTNXVMPowerState -Vmid $vmId -Transition ACPI_SHUTDOWN -verbose | Out-Null
    }

    $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'On'}
   
    $startTime = Get-Date
    $date = Get-Date
    $timeout = 30
    
    while ($desktops.Count -ne 0) {
  
        $desktops = Get-NTNXVM | Where-Object {$_.vmName -like "frame-instance-prod-*"} | Where-Object {$_.powerState -eq 'On'}
        Write-Host (Get-Date) ": $($desktops.Count) of $($totalDesktops) still running."
    
        $date = Get-Date
        if (($date - $startTime).TotalMinutes -gt $timeout) {
            Write-Error "Shutdown took to long." 
            Stop-Transcript
        }

        Start-Sleep 10
    }
}
