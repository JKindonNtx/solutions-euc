function Remove-LEAccountGroups {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][array]$ids
    )

    $Body = ConvertTo-Json @($ids)

    try {
        Invoke-PublicApiMethod -Method "DELETE" -Path "v6/account-groups" -Body $Body -ErrorAction Stop
    }
    catch {
        Write-Log -Message $_ -Level Error
        Break
    }

}
