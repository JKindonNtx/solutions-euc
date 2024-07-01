function Get-OmnissaDesktopPools {

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

    $URL = "$($ApiEndpoint)/rest/inventory/v1/desktop-pools"

    Write-Log -Message "Getting Desktop Pool $($PoolName) ID" -Level Info

    $desktopPools = invoke-restmethod -Method Get -uri $url -Headers $header -SkipCertificateCheck

    foreach ($pool in $desktopPools){
        if ($pool.name -eq $PoolName) {
            $Return = $pool
        }
    }
    
    Return $Return
}