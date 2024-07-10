function Remove-OmnissaManualPool {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolUuid
    )

    Write-Log -Message "Deleting Desktop Pool $($PoolUuid)" -Level Info
    $Path = "$($ApiEndpoint)/rest/inventory/v7/desktop-pools/$($PoolUuid)"
    $Pool = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "DELETE" -Path $Path

    Return $Pool
}