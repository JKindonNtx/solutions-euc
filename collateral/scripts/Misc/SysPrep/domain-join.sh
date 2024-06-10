#ps1_sysnative
$PrimaryADIPAddress = “1.1.1.1”
$Domain = ‘domain.com’
$AdUsername = “ad-svc-account”
# To convert a raw password into a base-64 encoding, run the following two Powershell commands:
# $bytes = [System.Text.Encoding]::Utf8.GetBytes('password')
# $Base64AdPassword = [System.Convert]::ToBase64String($bytes)
$Base64AdPassword = “hashed-password”
$Reboot = $False
$ErrorActionPreference = "Stop"if (-not (Get-WmiObject Win32_ComputerSystem).PartOfDomain) {
 netsh interface ip add dns name="Local Area Connection" addr=$PrimaryADIPAddress index=1
 $rawPassword = [System.Text.Encoding]::Utf8.GetString([System.Convert]::FromBase64String($Base64AdPassword))
 $password  = $rawPassword | ConvertTo-SecureString -AsPlainText -Force
 $cred = New-Object System.Management.Automation.PSCredential("$AdUsername", $password)
 Add-Computer -DomainName $Domain -Credential $cred
 shutdown -r -t 2
} 