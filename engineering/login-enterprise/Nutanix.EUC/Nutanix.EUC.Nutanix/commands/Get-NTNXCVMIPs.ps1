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
        $HostCVMips.Add($item.service_vmexternal_ip)
        Write-Log -Message "Adding CVM IP: $($item.service_vmexternal_ip) to Array" -Level Info
    }

    $HostCVMips

}
