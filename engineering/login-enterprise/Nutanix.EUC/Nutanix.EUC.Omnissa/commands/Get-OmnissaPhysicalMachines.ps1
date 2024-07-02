function Get-OmnissaPhysicalMachines {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$MachineNaming
    )

    $machines = New-Object System.Collections.Generic.List[System.Object]
    $Path = "$($ApiEndpoint)/rest/inventory/v2/physical-machines"
    $physicalMachines = Invoke-PublicApiMethodOmnissa -ApiEndpoint $ApiEndpoint -UserName $UserName -Password $Password -Domain $Domain -Method "GET" -Path $Path
    Write-Log -Message "Getting Manual machines to add to Desktop Pool" -Level Info

    foreach ($machine in $physicalMachines){
        if ($machine.name -like "$($MachineNaming)*") {
            $machines.Add($machine)
        }
    }
    
    Return $machines
}