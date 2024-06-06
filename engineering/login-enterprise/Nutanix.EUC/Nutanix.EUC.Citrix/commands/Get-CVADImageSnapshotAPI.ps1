function Get-CVADImageSnapshotAPI {
    param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DDC,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HypervisorConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$Snapshot,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$EncodedAdminCredential,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential
    )

    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-CVADAuthDetailsAPI -DDC $DDC -EncodedAdminCredential $EncodedAdminCredential -DomainAdminCredential $DomainAdminCredential

    Write-Log -Message "Looking for Snapshot $($Snapshot) via Hosting Connection $($HypervisorConnection)" -Level Info
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/hypervisors/$($HypervisorConnection)/allResources?path=$($Snapshot)&detail=true&?noCache=true"
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        $snapshot_exists = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }

    try {$snapshot_exists = $snapshot_exists} catch {$snapshot_exists = $null}

    if (-not [string]::IsNullOrEmpty($snapshot_exists)) {
        Write-Log -Message "Hosting Connection $($HypervisorConnection) has found Snapshot via path $($snapshot_exists.XDPath)" -Level Info
    } else {
        Write-Log -Message "Hosting Connection $($HypervisorConnection) cannot find requested Snapshot $($Snapshot)" -Level Error
        Break #Replace with Exit 1
    }
}

