function Get-NTNXHostIPs {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.Object]$Config
    )

    try {
        $HostData = Invoke-PublicApiMethodNTNX -Method "GET" -Path "hosts" -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Exit 1
    }
        
    $Hosts = $Hostdata.entities

    $Hostips = [System.Collections.ArrayList] @()

    foreach ($item in $Hosts) {
        [void]$Hostips.Add("$($item.hypervisor_address)")
        Write-Log -Message "Adding Host IP: $($item.hypervisor_address) to Array" -Level Info
    }

    return $Hostips

}
