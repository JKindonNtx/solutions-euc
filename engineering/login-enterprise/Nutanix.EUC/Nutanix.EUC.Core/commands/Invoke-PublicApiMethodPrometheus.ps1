function Invoke-PublicApiMethodPrometheus {
    param
    (
        $Path,
        [ValidateSet("POST", "GET", "PUT", "DELETE")]
        $Method = "GET",
        $Prometheusip,
        $PrometheusQuery,
        $starttime,
        $endtime,
        $ContentType = 'application/json'
    )

   # $prometheusserver = "10.57.70.0"
   # $prometheusQuery = "sum(shell_nvidia_smi_q{target_id=~'.*',GPU_UUID=~'.*',target_type=~'.*',target_ip=~'.*',metric_unit='Watts',metric='GPU power draw'}) by (target_id)"
    
    $step = "30"  # 30 seconds step

    $Body = @{ query = $prometheusQuery; start = $startTime; end = $endTime; step = $step }

    if ($PSEdition -eq "Core") {
        $count = 0
        $maxcount = 5
        $done = $false
        while ($done -eq $false) {
            $count++
            try {
                $URL = "http://$($Prometheusip):9090/api/v1/query_range"
                if ($null -ne $Body) {
                    Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -SkipCertificateCheck
                }
                else {
                    Invoke-RestMethod -Method $Method -Uri $URL -SkipCertificateCheck
                }
                $done = $true
            }
            catch {
                $reason = $_
                Write-Warning "API call failed, sleeping 2 seconds and trying again $($maxcount - $count) times: $_"
                Start-Sleep -Seconds 2
            }
            if ($count -eq $maxcount) {
                throw "API call failed after $($maxcount) times with reason: $reason"
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
                $URL = "http://$($Prometheusip):9090/api/v1/query_range"
                if ($null -ne $Body) {
                    Invoke-RestMethod -Body $Body -Method $Method -Uri $URL
                }
                else {
                    Invoke-RestMethod -Method $Method -Uri $URL
                }
                $done = $true
            }
            catch {
                $reason = $_
                Write-Warning "API call $url failed, sleeping 2 seconds and trying again $($maxcount - $count) times: $_"
                Start-Sleep -Seconds 2
            }
            if ($count -eq $maxcount) {
                throw "API call failed after $($maxcount) times with reason: $reason"
            }
        }
    }
}