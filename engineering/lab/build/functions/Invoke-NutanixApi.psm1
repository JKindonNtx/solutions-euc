function Invoke-NutanixApi {

    [CmdletBinding()]

    Param
    (
        $IP,
        $UserName,
        $Password,
        $APIPath,
        [ValidateSet("POST", "GET", "PUT", "DELETE")]$Method = "GET",
        $Body,
        $ContentType = 'application/json'
    )

    Begin
    {
        Set-StrictMode -Version Latest
        Write-Host (Get-Date)":Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" 
    } # Begin

    Process
    {
        # Display Function Parameters
        Write-Host (Get-Date)":API Path: $APIPath" 

        # Build JSON and connect to cluster for information
        $credPair = "$($UserName):$($Password)"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $header = @{ Authorization = "Basic $encodedCredentials" }
        $URL = "https://$($IP):9440/PrismGateway/services/rest/v2.0/$APIPath"

        if ($PSEdition -eq "Core") {
            if([string]::IsNullOrEmpty($Body)){
                try {
                    $Result = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -ContentType $ContentType -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Host -Message "API call failed: $_"
                }
            } else {
                try {
                    $Result = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -ContentType $ContentType -Body $Body -SkipCertificateCheck -ErrorAction Stop
                }
                catch {
                    Write-Host -Message "API call failed: $_"
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

            #[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls -bor [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLValidator]::GetDelegate()
            if([string]::IsNullOrEmpty($Body)){
                try {
                    $Result = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -ContentType $ContentType -ErrorAction Stop
                } catch {
                    Write-Host -Message "API call failed: $_"
                }
            } else {
                try {
                    $Result = Invoke-RestMethod -Method $Method -Uri $URL -Headers $Header -ContentType $ContentType -Body $Body -ErrorAction Stop
                } catch {
                    Write-Host -Message "API call failed: $_"
                }
            }
        }

    } # Process
    
    End
    {

        Write-Host (Get-Date)":Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" 
        return $Result

    } # End

} # Get-NutanixAPI
