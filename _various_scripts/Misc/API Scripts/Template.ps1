# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com
# Created on September, 2019
# Inspired by Lee Pryor at  https://medium.com/@leepryor

# Certificate information to call Nutanix Prism API
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
    ServicePoint srvPoint, X509Certificate certificate,
    WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

# Forcing PoSH to use TLS1.2 as it defaults to 1.0 and Prism requires 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Function to write a log to the host
Function write-log {
    <#
       .Synopsis
       Write logs for debugging purposes
       
       .Description
       This function writes logs based on the message including a time stamp for debugging purposes.
    #>
    param (
        $message,
        $sev = "INFO"
    )
    if ($sev -eq "INFO") {
        write-host "$(get-date -format "hh:mm:ss") | INFO | $message"
    }
    elseif ($sev -eq "WARN") {
        write-host "$(get-date -format "hh:mm:ss") | WARN | $message"
    }
    elseif ($sev -eq "ERROR") {
        write-host "$(get-date -format "hh:mm:ss") | ERROR | $message"
    }
    elseif ($sev -eq "CHAPTER") {
        write-host "`n`n### $message`n`n"
    }
} 

# Nutanix Prism information
$prism = "10.68.68.40"

# Nutanix login - username and password used to access the Nutanix cluster
$Credentials = get-credential -Message "Please enter your username and password for access to the Nutanix clusters (your domain creds)"

# Setup API Headers and Basic Connection info for connection to the surviving Nutanix cluster
$RESTAPIUser = $Credentials.GetNetworkCredential().UserName
$RESTAPIPassword = $Credentials.GetNetworkCredential().Password

# Nutanix Cluster and Prism REST API Connection information
$Uri = "https://$($prism):9440/PrismGateway/services/rest/v2.0/vms"
$Header = @{
"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($RESTAPIUser+":"+$RESTAPIPassword ))}


#API Call grabbing all VMs on the cluster
$VMs = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Header

# $uri2 = 'https://$($Prism):9440/PrismGateway/services/rest/v2.0/vms/'


# Looping thru the API call and setting the power state to ON
foreach ($vm in $VMs.entities){
                    if($vm.power_state -eq 'Off') {
                    $headers=@{}
                    $headers.Add("content-type", "application/json")
                    $newuri = "$uri/$($vm.uuid)/set_power_state"
                    $response = Invoke-WebRequest -Uri $newuri -Method POST -Headers $header -ContentType 'application/json' -Body '{"host_uuid":"string","transition":"ON","uuid":"string","vm_logical_timestamp":123}'
                    write-log -message "$($vm.name) is being powered on"
                    }
                    else{
                    # write-log -message "$($vm.name) was already powered on"
                    }
}
