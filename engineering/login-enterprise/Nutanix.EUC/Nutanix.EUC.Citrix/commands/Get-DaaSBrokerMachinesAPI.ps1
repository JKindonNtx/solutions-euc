function Get-DaaSBrokerMachinesAPI {

    [CmdletBinding()]

    param(
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DesktopPoolName,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CloudUrl,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$CustomerID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientID,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$ClientSecret,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][string]$DomainAdminCredential
    )

    #----------------------------------------------------------------------------------------------------------------------------
    # Check that creds aren't expired before proceeding
    #----------------------------------------------------------------------------------------------------------------------------
    $Global:Headers = Get-DaaSAuthDetailsAPI -CustomerID $CustomerID -ClientID $ClientID -ClientSecret $ClientSecret -CloudUrl $CloudUrl -DomainAdminCredential $DomainAdminCredential

        #----------------------------------------------------------------------------------------------------------------------------
    # Set API call detail
    #----------------------------------------------------------------------------------------------------------------------------
    $Method = "Get"
    $RequestUri = "https://$DDC/cvad/manage/jk_replace_this_please/"
    #----------------------------------------------------------------------------------------------------------------------------

    try {
        Write-Log -Message "Getting Broker Machines from $($DesktopPoolName)" -Level Info
        $BrokerMachines = (Invoke-RestMethod -Uri $RequestUri -Method $Method -Headers $Headers -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop).Items
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break #Replace with Exit 1
    }

    if (($BrokerMachines | Measure-Object).Count -gt 0) {
        Write-Log -Message "Retrieved $(($BrokerMachines | Measure-Object).Count) Machines from $($DesktopPoolName)" -Level Info
        return $BrokerMachines
    }
    else {
        Write-Log -Message "No Machines returned from $($DesktopPoolName)" -Level Warn
        return $null
    }

}