function Set-OmnissaRegistration {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmDnsName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmOperatingSystem,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain
    )

    $OmnissaConnection = Connect-OmnissaApi -url $ApiEndpoint -username $UserName -password $Password -domain $Domain
    
    $header = @{
            'Authorization' = "Bearer " + $OmnissaConnection.access_token
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }

    $Payload = "{ `
            ""dns_name"": """ + $VmDnsName + """, `
            ""operating_system"": """ + $VmOperatingSystem + """,
            ""message_security_mode"": ""DISABLED""
        }"

    $URL = "$($ApiEndpoint)/rest/inventory/v1/physical-machines/action/register"


 $URL = "$($ApiEndpoint)/rest/inventory/v1/physical-machines/890a7702-6cc0-45fb-9d37-f1fa85d51ec9"
invoke-restmethod -Method Get -uri $url -Body $Payload -Headers $header -SkipCertificateCheck

$URL = "$($ApiEndpoint)/rest/inventory/v1/physical-machines/8afa60ed-f6a2-433b-9294-7aadac827d44"
invoke-restmethod -Method Get -uri $url -Body $Payload -Headers $header -SkipCertificateCheck

    Write-Log -Message "Registering VM $($VmDnsName) to Omnissa" -Level Info
    invoke-restmethod -Method Post -uri $url -Body $Payload -Headers $header -SkipCertificateCheck
    
}

