function Set-OmnissaManualPoolMachines {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolID,
        $Payload
    )

    $Path = "$($ApiEndpoint)/rest/inventory/v1/desktop-pools/$($PoolID)/action/add-machines"
    Write-Log -Message "Adding Omnissa Manual Machines to Desktop Pool" -Level Info
    $desktopPools = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "POST" -Path $Path -Body $Payload
    
    Return $desktopPools
}