function Get-OmnissaMachines {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$PoolID,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Naming
    )

    $returnMachines = New-Object System.Collections.Generic.List[System.Object]
    $Path = "$($ApiEndpoint)/rest/inventory/v1/physical-machines"
    Write-Log -Message "Getting Omnissa machines" -Level Info
    $virtualMachines = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "GET" -Path $Path

    foreach ($machine in $virtualMachines){
        if($PoolID -ne "") {
            if ($machine.desktop_pool_id -eq "$($PoolID)") {
                $returnMachines.Add($machine)
            }
        } else {
            if($Naming -ne ""){
                $MachineName = $machine.name
                if($MachineName -like "$($Naming)*") {
                    $returnMachines.Add($machine)
                }
            } else {
                $returnMachines.Add($machine)
            }
        }
    }
    
    Return $returnMachines
}