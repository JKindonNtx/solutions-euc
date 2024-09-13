function Get-NTNXCVMIPs {

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

    $HostCVMips = [System.Collections.ArrayList] @()

    foreach ($item in $Hosts) {
        [void]$HostCVMips.Add($item.service_vmexternal_ip)
    }

    Write-Log -Message "Added $(($HostCVMips | Measure-Object).Count) Host CVM IPs to Array for Observer monitoring" -Level Info

    return $HostCVMips

}
