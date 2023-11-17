function Invoke-PublicApiMethod {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$Path,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][ValidateSet("POST", "GET", "PUT", "DELETE")][String]$Method,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][String]$Body,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$ContentType = 'application/json',
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$OutFile,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $false)][String]$Form
    )

    $Header = @{
        "Accept"        = "application/json"
        "Authorization" = "Bearer $global:LE_Token"
        "Content-Type"  = $ContentType
    }

    if ($PSEdition -eq "Core") {
        $count = 0
        $maxcount = 5
        $done = $false
        while ($done -eq $false) {
            $count++
            try {
                $URL = "$($global:LE_URL)/publicApi/$Path"
                if ($null -ne $Body) {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -OutFile $OutFile -ErrorAction Stop
                    }
                    else {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -ErrorAction Stop
                    }
                }
                else {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -OutFile $OutFile -ErrorAction Stop
                    }
                    elseif ($null -ne $Form) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -Form $Form -ErrorAction Stop
                    }
                    else {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -ErrorAction Stop
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
                Break
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
                $URL = "$($global:LE_URL)/publicApi/$Path"
                if ($null -ne $Body) {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -OutFile $OutFile -ErrorAction Stop
                    }
                    else {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -ErrorAction Stop
                    }
                }
                else {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -OutFile $OutFile -ErrorAction Stop
                    }
                    elseif ($null -ne $Form) {
                        #Write-Host "TODO fix form multi/part data upload for non-pscore"
                            
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
                        $client.DefaultRequestHeaders.Authorization = "Bearer $global:LE_Token"
                        $result = $client.PostAsync($url, $content).Result
                        if ($result.IsSuccessStatusCode -eq $false) {
                            throw "Failed to upload $filePath"
                        }
                        $result.Content.ReadAsStringAsync().Result.Trim("`"")

                    }
                    else {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -ErrorAction Stop
                    }
                }
                $done = $true
            }
            catch {
                $reason = $_
                Write-Log -Message "API call $url failed, sleeping 2 seconds and trying again $($maxcount - $count) times: $_" -Level Warn
                Start-Sleep -Seconds 2
            }
            if ($count -eq $maxcount) {
                Write-Log -Message "API call failed after $($maxcount) times with reason: $reason" -Level Error
                Break
            }
        }
    }
}
