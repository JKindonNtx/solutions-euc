function Invoke-PublicApiMethodFiles {

    [CmdletBinding()]

    Param (
        $Path,
        [ValidateSet("POST", "GET", "PUT", "DELETE")]
        $Method = "GET",
        $Body,
        $ContentType = 'application/json',
        $OutFile,
        $Form
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        $header = @{
            Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($VSI_Target_Files_api) + ":" + $($VSI_Target_Files_Password)))
            "Accept-Encoding" = "gzip"
            "Accept"        = "application/json"
        }

        if ($PSEdition -eq "Core") {
        $count = 0
        $maxcount = 5
        $done = $false
        while ($done -eq $false) {
            $count++
            try {
                $URL = "https://$($VSI_Target_Files):9440/api/$Path"
                if ($null -ne $Body) {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -OutFile $OutFile -ErrorAction Stop
                    } else {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -ErrorAction Stop
                    }
                } else {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -OutFile $OutFile -ErrorAction Stop
                    } elseif ($null -ne $Form) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -Form $Form -ErrorAction Stop
                    } else {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -SkipCertificateCheck -ErrorAction Stop
                    }
                }
                $done = $true
            } catch {
                $reason = $_
                Write-Warning "API call failed, sleeping 2 seconds and trying again $($maxcount - $count) times: $_"
                Start-Sleep -Seconds 2
            }
            if ($count -eq $maxcount) {
                throw "API call failed after $($maxcount) times with reason: $reason"
            }
        }
    } else {
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
                $URL = "https://$($VSI_Target_Files):9440/api/$Path"
                if ($null -ne $Body) {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -OutFile $OutFile -ErrorAction Stop
                    } else {
                        Invoke-RestMethod -Body $Body -Method $Method -Uri $URL -Headers $Header -ErrorAction Stop
                    }
                } else {
                    if ($null -ne $OutFile) {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -OutFile $OutFile -ErrorAction Stop
                    } elseif ($null -ne $Form) {
                        
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
                        $client.DefaultRequestHeaders.Authorization = $($VSI_Target_Files_Password)
                        $result = $client.PostAsync($url, $content).Result
                        if ($result.IsSuccessStatusCode -eq $false) {
                            throw "Failed to upload $filePath"
                        }
                        $result.Content.ReadAsStringAsync().Result.Trim("`"")

                    } else {
                        Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -ErrorAction Stop
                    }
                }
                $done = $true
            } catch {
                $reason = $_
                Write-Log -Message "API call $url failed, sleeping 2 seconds and trying again $($maxcount - $count) times: $_" -Level Warn
                Start-Sleep -Seconds 2
            }
            if ($count -eq $maxcount) {
                Write-Log -Message "API call failed after $($maxcount) times with reason: $reason" -Level Error
                Exit 1
            }
        }
    }

    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
