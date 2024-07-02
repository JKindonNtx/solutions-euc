function Connect-OmnissaApi(){
    param(
        [string] $username,
        [string] $password,
        [string] $domain,
        [string] $url
    )

    $Credentials = New-Object psobject -Property @{
        username = $username
        password = $password
        domain = $domain
    }

    $Path = "$($ApiEndpoint)/rest/login"

    if ($PSEdition -eq "Core") {
        $count = 0
        $maxcount = 5
        $done = $false
        while ($done -eq $false) {
            $count++
            try {
                $URL = $Path
                $Return = Invoke-RestMethod -ContentType "application/json" -Body ($Credentials | ConvertTo-Json) -Method "POST" -Uri $URL -SkipCertificateCheck
                $done = $true
            }
            catch {
                $reason = $_
                Write-Log -Message "API call failed, sleeping 2 seconds and trying again $($maxcount - $count) times: $_" -Level Warn
                Start-Sleep -Seconds 2
            }
            if ($count -eq $maxcount) {
                Write-Log -Message "API call failed after $($maxcount) times with reason: $reason" -Level Error
                Exit 1
            }
        }
    }
    else {
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
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLValidator]::GetDelegate()
        $count = 0
        $maxcount = 5
        $done = $false
        while ($done -eq $false) {
            $count++
            try {
                $URL = $Path
                $Return = Invoke-RestMethod -ContentType "application/json" -Body ($Credentials | ConvertTo-Json) -Method "POST" -Uri $URL
                $done = $true
            }
            catch {
                $reason = $_
                Write-Log "API call $url failed, sleeping 2 seconds and trying again $($maxcount - $count) times: $_" -Level Warn
                Start-Sleep -Seconds 2
            }
            if ($count -eq $maxcount) {
                Write-Log -Message "API call failed after $($maxcount) times with reason: $reason" -Level Error
                Exit 1
            }
        }
    }

    return $Return

}