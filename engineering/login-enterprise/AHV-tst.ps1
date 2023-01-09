#$Username = $configAHVServer.username
#$Password = $configAHVServer.Password
$ConfigAHVserver = "10.56.68.25"
$storage = "VDI"
$Username = "admin"
$Password = "Nutanix/4u$"
$header = @{
    Authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Username + ":" + $Password))
}

$uri = "https://$($configAHVServer):9440/PrismGateway/services/rest/v2.0/storage_containers"

#Block to ignore certificate errors
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()

# $Containerinfo = Invoke-RestMethod -Method GET -Uri $uri -Header $header | Where-Object {$_.name -eq $storage}
$Containerinfo = Invoke-RestMethod -Method GET -Uri $uri -Header $header
$Containeritem = $Containerinfo.entities | Where-Object {$_.name -eq $storage}
#$containeritem
$ContainerId = ($Containeritem.id.split(":"))[2]
$ContainerId