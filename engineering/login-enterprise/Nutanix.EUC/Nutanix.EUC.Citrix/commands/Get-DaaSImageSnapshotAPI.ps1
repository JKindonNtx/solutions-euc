function Get-DaaSImageSnapshotAPI {
    param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CloudUrl,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$HypervisorConnection,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$Snapshot,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientSecret,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CustomerID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential
    )

    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-DaaSAuthDetailsAPI -CustomerID $CustomerID -ClientID $ClientID -ClientSecret $ClientSecret -CloudUrl $CloudUrl -DomainAdminCredential $DomainAdminCredential

    Write-Log -Message "Looking for Snapshot $($Snapshot) via Hosting Connection $($HypervisorConnection)" -Level Info
    #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$CloudUrl/cvad/manage/hypervisors/$($HypervisorConnection)/allResources?path=$($Snapshot)&detail=true&?noCache=true"
    #----------------------------------------------------------------------------------------------------------------------------
    try {
        $snapshot_exists = Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    try {$snapshot_exists = $snapshot_exists} catch {$snapshot_exists = $null}

    if (-not [string]::IsNullOrEmpty($snapshot_exists)) {
        Write-Log -Message "Hosting Connection $($HypervisorConnection) has found Snapshot $($Snapshot) via path $($snapshot_exists.XDPath)" -Level Info
    } else {
        Write-Log -Message "Hosting Connection $($HypervisorConnection) cannot find requested Snapshot $($Snapshot)" -Level Error
        Break #Replace with Exit 1
    }
}

