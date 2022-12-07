
$launchers = @()
$numberOfVms = 28

for ($i = 28; $i -le $numberOfVms; $i++) {
    $number = "{0:00}" -f $i
    $launchers += "VSI3LAUNCH$number"
}


$key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$name = "ScreenResolution"
$value = "Powershell.exe -ExecutionPolicy Bypass -File \\WS-VSI3\LoginVSI\_VSI_Scripts\General\Set-ScreenResolution.ps1"
foreach ($launcher in $launchers) { 

    Invoke-Command -ComputerName $launcher -ScriptBlock {New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "ScreenResolution" -Value "Powershell.exe -ExecutionPolicy Bypass -File \\WS-VSI3\LoginVSI\_VSI_Scripts\General\Set-ScreenResolution.ps1" -PropertyType string -Force}
    Restart-Computer -ComputerName $launcher -Force
}
