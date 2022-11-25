# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on September, 2019

# Get screensaver settings and change the values if needed

$screensaver = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\8EC4B3A5-6868-48c2-BE75-4F3044BE88A7\ -Name "Attributes"

if ($screensaver.attributes -eq "1") {
    write-host "Screensaver: Already set"
    }

else {
    write-host "Changing the screen saver to none"
    Set-Itemproperty -path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\8EC4B3A5-6868-48c2-BE75-4F3044BE88A7\' -Name 'Attribute' -value '1'
     }


# Collecting current power scheme and changing power options if needed

$currentPowerScheme = Powercfg -getactivescheme
$currentPowerScheme = $currentPowerScheme.split("()")
Write-Host "Current Power Scheme:" $currentPowerScheme[1]

$DisplaySettings = powercfg -query SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e
$DisplaySettings = $DisplaySettings[10].Split(":")[-1]

if ($DisplaySettings -like '*0x00000000') {
    Write-host 'Display Settings: Configured to Never turn off the display'
    break
    }

Else {
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
}

