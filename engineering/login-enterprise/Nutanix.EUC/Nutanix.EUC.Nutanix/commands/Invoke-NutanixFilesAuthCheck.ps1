function Invoke-NutanixFilesAuthCheck {

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
        $Method = "GET"
        $URL = "https://$($VSI_Target_Files):9440/api/files/v4.0.a2/config/file-server"
        #$URL = "https://10.57.64.106:9440/api/files/v4.0.a2/config/file-server"
        $header = @{
            Authorization     = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($($VSI_Target_Files_api) + ":" + $($VSI_Target_Files_Password)))
            "Accept-Encoding" = "gzip"
            "Accept"          = "application/json"
        }

        if ($PSEdition -eq "Core") {
            try {
                $FilesAuthCheck = Invoke-RestMethod -Method $Method -Uri $URL -Headers $header -SkipCertificateCheck -ErrorAction Stop
                Write-Log -Message "Successfully Authenticated to Files Environment"
            }
            catch {
                Write-Log -Message $_ -Level Error
                Write-Log -Message "Failed to Authenticate to Nutanix Files Environment. Please check credentials. Exiting Script" -Level Error
                Exit 1
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

            try {
                $FilesAuthCheck = Invoke-RestMethod -Method $Method -Uri $URL -Headers $header -ErrorAction Stop
                Write-Log -Message "Successfully Authenticated to Files Environment"
            }
            catch {
                Write-Log -Message $_ -Level Error
                Write-Log -Message "Failed to Authenticate to Nutanix Files Environment. Please check credentials. Exiting Script" -Level Error
                Exit 1
            }
        }
    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
