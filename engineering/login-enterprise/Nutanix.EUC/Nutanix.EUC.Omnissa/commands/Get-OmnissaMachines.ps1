function Get-OmnissaMachines {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolID
    )

    $returnMachines = New-Object System.Collections.Generic.List[System.Object]
    $Path = "$($ApiEndpoint)/rest/inventory/v1/machines"
    $virtualMachines = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "GET" -Path $Path
    Write-Log -Message "Getting Omnissa machines" -Level Info

    foreach ($machine in $virtualMachines){
        if ($machine.desktop_pool_id -eq "$($PoolID)") {
            $returnMachines.Add($machine)
        }
    }
    
    Return $returnMachines
}