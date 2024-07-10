function New-OmnissaManualPool {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolName
    )

    $Path = "$($ApiEndpoint)/rest/config/v2/local-access-groups"
    $Entitlements = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "GET" -Path $Path

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

    $desktopPoolPath = "$($ApiEndpoint)/rest/inventory/v2/desktop-pools"
    Write-Log -Message "Creating Desktop Pool $($PoolName)" -Level Info
    $Pool = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "POST" -Path $desktopPoolPath -Body $Payload
    
    Return $Pool
}