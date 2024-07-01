function Get-OmnissaPhysicalMachines {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$ApiEndpoint,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$UserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Password,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$MachineNaming
    )

    $OmnissaConnection = Connect-OmnissaApi -url $ApiEndpoint -username $UserName -password $Password -domain $Domain
    $machines = New-Object System.Collections.Generic.List[System.Object]

    $header = @{
            'Authorization' = "Bearer " + $OmnissaConnection.access_token
            'Accept' = "application/json"
            'Content-Type' = "application/json"
        }

    $URL = "$($ApiEndpoint)/rest/inventory/v2/physical-machines"
    $physicalMachines = invoke-restmethod -Method Get -uri $url -Headers $header -SkipCertificateCheck

    Write-Log -Message "Getting Manual machines to add to Desktop Pool" -Level Info

    foreach ($machine in $physicalMachines){
        if ($machine.name -like "$($MachineNaming)*") {
            $machines.Add($machine)
        }
    }
    
    Return $machines
}