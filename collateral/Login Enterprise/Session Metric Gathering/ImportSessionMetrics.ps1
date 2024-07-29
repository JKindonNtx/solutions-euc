param (
    [string]$filePath,
    [string]$fqdn,
    [string]$token
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Script requires powershell 7 or later"
    Exit 0
}

$global:FQDN = $fqdn
$global:TOKEN = $token
$global:HEADER = @{
    "Accept" = "application/json"
    "Authorization" = "Bearer $global:TOKEN"
}
$version = "v7-preview"
$global:metricDefinitionEndpoint = "/publicApi/$version/user-session-metric-definitions"

function Main {
    # Add SSL Handler
    $SSLHandler = @"
public class SSLHandler
{public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
{return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });}
}
"@
    try {Add-Type -TypeDefinition $SSLHandler} catch {Write-Host "SSL Handler already exists."}

    $json = Get-Content -Path $filePath -Raw | ConvertFrom-Json

    $table = @()
    foreach ($definition in $json) {
        $requestBody = $definition | ConvertTo-Json
        try {
            $id = Import-VSISessionMetric -metricDefinition $requestBody -ErrorAction Stop
        }
        catch {
            Write-Host "Failed to import metric definition: $(($requestBody | ConvertFrom-JSON).name). Check if User session metric definition already exists."
            Continue
        }
        
        if ($id) {
            if ($definition.type -eq "WmiQuery") {
                $definitionRow = [PSCustomObject]@{
                    id = $id
                    name = $definition.measurements.displayName
                }
            } 
            elseif ($definition.type -eq "PerformanceCounter") {
                $definitionRow = [PSCustomObject]@{
                    id = $id
                    name = $definition.measurement.displayName
                }
            }
            else {
                $definitionRow = [PSCustomObject]@{
                    id = $id
                    name = $definition.displayName
                }
            } 
            # Add table row of id, name for API usage.
            $table += $definitionRow
        }
    }

    $table
}

function Import-VSISessionMetric {
    param (
        $metricDefinition
    )
    
    # only required for older versions of powershell/.net
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11

    # warning: ignoring SSL/TLS certificates is a security risk
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()
    
    # set parameters
    $Parameters = @{
        Uri                  = 'https://' + $global:Fqdn + $global:metricDefinitionEndpoint
        Headers              = $global:HEADER
        Method               = 'POST'
        body                 = $metricDefinition
        ContentType          = 'application/json'
        SkipCertificateCheck = $true
    }
    $Response = Invoke-RestMethod @Parameters
    $Response.id
}

Main
