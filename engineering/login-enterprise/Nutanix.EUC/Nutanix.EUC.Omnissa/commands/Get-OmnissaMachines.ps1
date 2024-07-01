function Get-OmnissaMachines {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolID
    )

    $OmnissaConnection = Connect-OmnissaApi -url $ApiEndpoint -username $UserName -password $Password -domain $Domain
    $returnMachines = New-Object System.Collections.Generic.List[System.Object]

    $header = @{
            'Authorization' = "Bearer " + $OmnissaConnection.access_token
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }

    $URL = "$($ApiEndpoint)/rest/inventory/v1/machines"
    $virtualMachines = invoke-restmethod -Method Get -uri $url -Headers $header -SkipCertificateCheck

    Write-Log -Message "Getting Omnissa machines" -Level Info

    foreach ($machine in $virtualMachines){
        if ($machine.desktop_pool_id -eq "$($PoolID)") {
            $returnMachines.Add($machine)
        }
    }
    
    Return $returnMachines
}