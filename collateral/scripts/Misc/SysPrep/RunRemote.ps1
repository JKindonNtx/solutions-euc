$s = New-PSSession -ComputerName "SRV1"
Invoke-Command -Session $s -ScriptBlock {$services = Get-Service}
Invoke-Command -Session $s -ScriptBlock {$services | Where-Object {$_.Status -eq "Stopped"}}
Remove-PSSession $s


Invoke-Command –computername “10.68.68.117” -Credential administrator –command {H:\PoSH Scripts\RunSysPrep_v0.96.ps1 -RegisteredName Nutanix -Organization Nutanix -DomainName Contoso.local -DomainUser administrator -DomainPwd Nutanix/4u} 


$xml.unattend.settings[0].component[1].UserData.FullName = $RegisteredName
$xml.unattend.settings[0].component[1].UserData.Organization = $Organization
$xml.unattend.settings[2].component[1].ComputerName = $ComputerName
$xml.unattend.settings[2].component[2].identification.JoinDomain = $DomainName
$xml.unattend.settings[2].component[2].identification.credentials.UserName = $DomainUser
$xml.unattend.settings[2].component[2].identification.credentials.Password = ConvertTo-PlainText $DomainPwd
$xml.unattend.settings[2].component[2].identification.credentials.Domain = $DomainName


.\psexec \\10.68.68.113 cmd /c "echo . | powershell hostname"


.\PSExec \\10.68.68.113 -i -u administrator -p nutanix/4u PowerShell RunSysPrep_v0.96.ps1  -RegisteredName Nutanix -Organization Nutanix -DomainName Contoso.local -DomainUser administrator -DomainPwd Nutanix/4u