function New-LEAccounts {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][string]$Username,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][Int32]$NumberOfDigits,
        [Parameter(Mandatory = $true)][Int32]$NumberOfAccounts
    )


        $ExistingAccounts = Get-LEAccounts | Where-Object { $_.username -like "$($Username)*" -and $_.domain -eq $domain }
        If ($null -ne $ExistingAccounts) {
            Remove-LEAccounts -ids ($ExistingAccounts | Select-Object -ExpandProperty id) | Out-Null
        }

        Write-Log -Message "Creating LE accounts for $Username" -Level Info

        $Body = @{
            numberOfDigits   = $NumberOfDigits
            numberOfAccounts = $numberOfAccounts
            username         = $username
            domain           = $domain
            password         = $password
        } | ConvertTo-Json

        try {
            $Response = Invoke-PublicApiMethod -Method "POST" -Path 'v6/accounts/bulk' -Body $Body -ErrorAction Stop
            $Response.idList
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }



}
