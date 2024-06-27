function Invoke-PublicApiMethodOmnissa {
    param
    (
        $Path,
        [ValidateSet("POST", "GET", "PUT", "DELETE")]
        $Method = "GET",
        $Body,
        $ContentType = 'application/json',
        $OutFile,
        $Form,
        [Parameter(Mandatory = $false)][String]$TargetApiClient,
        [Parameter(Mandatory = $false)][String]$TargetApiAdmin,
        [Parameter(Mandatory = $false)][String]$TargetApiPassword
    )

    if ($TargetCVM) {
        $header = @{
            'Authorization' = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($TargetCVMAdmin) + ":" + $($TargetCVMPassword)))
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }
    }
    else {
        $header = @{
            Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($VSI_Target_CVM_admin) + ":" + $($VSI_Target_CVM_Password)))
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }
    }
    

    if ($PSEdition -eq "Core") {
        $count = 0
        $maxcount = 5
        $done = $false
        while ($done -eq $false) {
            $count++
            try {
                if ($TargetCVM) {
                    $URL = "https://$($TargetCVM):9440/PrismGateway/services/rest/v2.0/$Path"
                }
                else {
                    $URL = "https://$($VSI_Target_CVM):9440/PrismGateway/services/rest/v2.0/$Path"
                }
                
                if ($null -ne $Body) {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -OutFile $OutFile
                    }
                    else {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck
                    }
                }
                else {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -OutFile $OutFile
                    }
                    elseif ($null -ne $Form) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -Form $Form
                    }
                    else {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck
                    }
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
                if ($TargetCVM) {
                    $URL = "https://$($TargetCVM):9440/PrismGateway/services/rest/v2.0/$Path"
                }
                else {
                    $URL = "https://$($VSI_Target_CVM):9440/PrismGateway/services/rest/v2.0/$Path"
                }
                
                if ($null -ne $Body) {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -OutFile $OutFile
                    }
                    else {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header
                    }
                }
                else {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -OutFile $OutFile
                    }
                    elseif ($null -ne $Form) {
                        
                        $FilePath = $Form.Values[0]
                        $FileName = $(Split-Path $FilePath -Leaf)
                        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath);
                        $fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes);
                        $boundary = [System.Guid]::NewGuid().ToString();
                        $LF = "`r`n";
                
                        $bodyLines = (
                            "--$boundary",
                            "Content-Disposition: form-data; name=`"file`"; file=`"$FileName`"",
                            "Content-Type: application/octet-stream$LF",
                            $fileEnc,
                            "--$boundary--$LF"
                        ) -join $LF
                
                        $splat = @{
                            uri         = $URL
                            headers     = $Header
                            method      = "POST"
                            ContentType = "multipart/form-data; boundary=`"$boundary`""
                            Body        = $bodylines                        
                        }
                        
                        Add-Type -AssemblyName 'System.Net.Http'
                        
                        $client = New-Object System.Net.Http.HttpClient
                        $content = New-Object System.Net.Http.MultipartFormDataContent
                        $fileStream = [System.IO.File]::OpenRead($filePath)
                        $fileName = [System.IO.Path]::GetFileName($filePath)
                        $fileContent = New-Object System.Net.Http.StreamContent($fileStream)
                        $content.Add($fileContent, $Form.Keys[0], $fileName)
                        if ($TargetCVM) {
                            $client.DefaultRequestHeaders.Authorization = $($TargetCVMPassword)
                        }
                        else {
                            $client.DefaultRequestHeaders.Authorization = $($VSI_Target_CVM_Password)
                        }
                        $result = $client.PostAsync($url, $content).Result
                        if ($result.IsSuccessStatusCode -eq $false) {
                            Write-Log -Message "Failed to upload $filePath" -Level Error
                            Exit 1
                        }
                        $result.Content.ReadAsStringAsync().Result.Trim("`"")
                    }
                    else {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header
                    }
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