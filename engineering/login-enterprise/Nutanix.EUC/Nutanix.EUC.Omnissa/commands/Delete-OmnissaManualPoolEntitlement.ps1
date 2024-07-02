function Delete-OmnissaManualPoolEntitlement {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolID,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$GroupID
    )

    $Path = "$($ApiEndpoint)/rest/entitlements/v1/desktop-pools"

    $Payload = "[ `
        { `
            ""ad_user_or_group_ids"": [ `
                """ + $GroupID + """ `
            ], `
            ""id"": """ + $PoolID + """ `
        } `
    ]"

    Write-Log -Message "Removing Omnissa Manual Desktop Pool Entitlement" -Level Info
    $poolAssignment = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "DELETE" -Path $Path -Body $Payload
    
    Return $poolAssignment
}