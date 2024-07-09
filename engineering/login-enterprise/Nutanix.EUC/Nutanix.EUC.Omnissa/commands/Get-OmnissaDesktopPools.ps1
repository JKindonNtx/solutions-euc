function Get-OmnissaDesktopPools {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolName
    )

    $Path = "$($ApiEndpoint)/rest/inventory/v1/desktop-pools"
    Write-Log -Message "Getting Desktop Pool $($PoolName) ID" -Level Info

    $desktopPools = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "GET" -Path $Path

    foreach ($pool in $desktopPools){
        if ($pool.name -eq $PoolName) {
            $Return = $pool
            break
        } else {
            $Return = "NoPool"
        }
    }
    
    Return $Return
}