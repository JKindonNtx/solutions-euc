function New-OmnissaManualPool {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolName
    )

    $OmnissaConnection = Connect-OmnissaApi -url $ApiEndpoint -username $UserName -password $Password -domain $Domain
    
    $header = @{
            'Authorization' = "Bearer " + $OmnissaConnection.access_token
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }

    $URL = "$($ApiEndpoint)/rest/config/v2/local-access-groups"
    $Entitlements = invoke-restmethod -Method Get -uri $url -Headers $header -SkipCertificateCheck

    foreach ($ent in $Entitlements){
        if ($ent.name -eq "Root") {
            $AccessGroupID = $ent.id
        }
    }

    $Payload = "{ `
            ""name"": """ + $PoolName + """, `
            ""source"": ""UNMANAGED"",
            ""type"": ""MANUAL"",
            ""user_assignment"": ""FLOATING"",
            ""access_group_id"": """ + $AccessGroupID + """,
            ""display_protocol_settings"": {
                ""default_display_protocol"": ""BLAST""
            }
        }"

    $URL = "$($ApiEndpoint)/rest/inventory/v2/desktop-pools"

    Write-Log -Message "Creating Desktop Pool $($PoolName)" -Level Info
    $Pool = invoke-restmethod -Method Post -uri $url -Body $Payload -Headers $header -SkipCertificateCheck
    
    Return $Pool
}