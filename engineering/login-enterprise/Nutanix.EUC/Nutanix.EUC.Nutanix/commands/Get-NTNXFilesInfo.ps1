function Get-NTNXFilesInfo {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.Object]$Config
    )


    try {
        $filesinfo = Invoke-PublicApiMethodFiles -Method "GET" -Path "files/v4.0.a5/config/file-servers" -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }

    $config.Target.files_name = $filesinfo.data.name
    $config.Target.files_uuid = $filesinfo.data.extId
    $config.Target.files_version = $filesinfo.data.version
    $config.Target.files_vmscount = $filesinfo.data.nvmsCount
    $config.Target.files_vcpus = $filesinfo.data.vcpus
    $config.Target.files_memorygb = $filesinfo.data.memoryGib
    $config.Target.files_ips = $filesinfo.data.InternalNetworks.ipAddresses.ipv4.value
   
    $Config
}


