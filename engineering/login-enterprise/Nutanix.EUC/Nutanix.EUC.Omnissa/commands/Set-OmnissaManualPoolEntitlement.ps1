function Set-OmnissaManualPoolEntitlement {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolID,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$GroupID
    )

    $OmnissaConnection = Connect-OmnissaApi -url $ApiEndpoint -username $UserName -password $Password -domain $Domain
    
    $header = @{
            'Authorization' = "Bearer " + $OmnissaConnection.access_token
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }

    $URL = "$($ApiEndpoint)/rest/entitlements/v1/desktop-pools"

    $Payload = "[ `
        { `
            ""ad_user_or_group_ids"": [ `
                """ + $GroupID + """ `
            ], `
            ""id"": """ + $PoolID + """ `
        } `
    ]"

    Write-Log -Message "Setting Omnissa Manual Desktop Pool Entitlement" -Level Info

    $poolAssignment = invoke-restmethod -Method Post -uri $url -Headers $header -body $Payload -SkipCertificateCheck
    
    Return $poolAssignment
}