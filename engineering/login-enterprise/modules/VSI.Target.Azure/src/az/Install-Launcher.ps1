Param(
    $credential,
    $applianceUrl
)
Start-Sleep -Seconds 30
Start-Transcript -Path C:\installauncher.log

Write-Host "Downloading launcher from $applianceUrl, using $credential"
if (-not("SSLValidator" -as [type])) {
    add-type -TypeDefinition @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class SSLValidator {
    public static bool ReturnTrue(object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors) { return true; }

    public static RemoteCertificateValidationCallback GetDelegate() {
        return new RemoteCertificateValidationCallback(SSLValidator.ReturnTrue);
    }
}
"@
}
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLValidator]::GetDelegate()

$Body = @{"grant_type" = "client_credentials"; "scope" = "microservice"; "client_id" = "Engine"; "client_secret" = "6ZY59S36VICWA7FQNYDKOEC004VHAHT0PB5C2CP3" }
$Req = Invoke-RestMethod -uri "$applianceUrl/identityServer/connect/token" -Body $Body -Headers @{"Content-Type" = "application/x-www-form-urlencoded"; "Authorization" = "Token" } -Method Post	
$Headers = @{"Authorization" = "Bearer $($Req.access_token)"; "Content-Type" = "application/json" }


if (-not (Test-Path "C:\launcher_win10_x64")) {
    Invoke-WebRequest -OutFile "C:\launcher_win10_x64.zip" -Uri "$applianceUrl/contentDelivery/content/zip/launcher_win10_x64.zip" -Headers $Headers -UseBasicParsing
    Expand-Archive -Path "C:\launcher_win10_x64.zip" -DestinationPath "C:\launcher_win10_x64"
}


Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value 1 -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUserName" -Value $credential.split(";")[0] -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value $credential.split(";")[1] -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultDomainName" -Value $env:COMPUTERNAME -Force
Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoLogonCount" -Value 999 -Force
Remove-ItemProperty -Path "HKLM:Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoLogonSID" -Force -Erroraction silentlycontinue


If (-not (Test-Path "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe")) {
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "PILauncher_Install" -Value 'cmd /c msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log" && shutdown /r /t 0' -Force
    #Start-Sleep -Seconds 120
    #msiexec /i "C:\launcher_win10_x64\setup.msi" /qn /liewa "C:\launcher_win10_x64\install.log"
}
If ($null -eq (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "PILauncher" -ea silent)) {
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run -Name "PILauncher" -Value "C:\Program Files\Login VSI\Login PI 3 Launcher\LoginPI.Launcher.exe" -Force
    Restart-Computer -Force
}
Stop-Transcript