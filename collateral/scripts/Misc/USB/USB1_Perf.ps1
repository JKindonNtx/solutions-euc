$USBControllers = Get-PnPDevice | Where-Object {$_.Class -match "USB"}

if ($USBControllers | Where-Object {$_.InstanceId -like "*0001*"})
{
    Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\usbflags" -Recurse
    Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\USB" -Recurse
    Write-Host "USB1 devices found"
}
else 
{
    Write-Host "USB2 devices found"
}