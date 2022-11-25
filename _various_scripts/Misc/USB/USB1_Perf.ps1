$USBControllers =Get-PnPDevice | where {$_.Class -Match "USB"}

if ($USBControllers | ?{$_.instanceid -like "*0001*"})
{
Remove-Item -Path HLM\SYSTEM\CurrentControlSet\Control\usbflags -Recurse
Remove-Item -Path HLM\SYSTEM\CurrentControlSet\Enum\USB -Recurse
Write-Host "USB1 devices found"
}
else 
{
Write-Host "USB2 devices found"
}