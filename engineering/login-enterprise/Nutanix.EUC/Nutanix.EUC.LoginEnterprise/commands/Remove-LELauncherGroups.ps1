function Remove-LELauncherGroups {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, mandatory = $true)][array]$ids
    )

    $Body = ConvertTo-Json @($ids)

    try {
        $Response = Invoke-PublicApiMethod -Method "DELETE" -Path "v6/launcher-groups" -Body $Body
        
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }
        
}
