function Connect-LEAppliance {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.String]$URL,
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][System.String]$Token
    )

    $global:LE_URL = $url.TrimEnd("/")
    $global:LE_Token = $token

    if ($null -eq (Get-LEApplications)) {
        Write-Log -Message "Failed to connect to appliance at $url, please check that the URL and Token are correct" -Level Error
        Break
    }
    else {
        Write-Log -Message "Connected to VSI Appliance at URL: $($global:LE_URL)" -Level Info
    }

}
