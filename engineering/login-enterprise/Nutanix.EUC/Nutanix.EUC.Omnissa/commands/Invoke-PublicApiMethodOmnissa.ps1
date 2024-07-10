function Invoke-PublicApiMethodOmnissa {
    param
    (
        $Path,
        $Method,
        $Body,
        [Parameter(Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(Mandatory = $false)][String]$UserName,
        [Parameter(Mandatory = $false)][String]$Password,
        [Parameter(Mandatory = $false)][String]$Domain
    )

    $OmnissaConnection = Connect-OmnissaApi -url $ApiEndpoint -username $UserName -password $Password -domain $Domain
    
    $header = @{
            'Authorization' = "Bearer " + $OmnissaConnection.access_token
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }

    $URL = "$($ApiEndpoint)/$Path"
    

    if ($PSEdition -eq "Core") {
        $count = 0
        $maxcount = 5
        $done = $false
        while ($done -eq $false) {
            $count++
            try {
                $URL = $Path
                
                if ($null -ne $Body) {
                    Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck
                }
                else {
                    Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck
                }
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

                if ($null -ne $Body) {
                    Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header
                }
                else {
                    Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header
                }
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
}