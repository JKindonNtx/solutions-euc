function New-LEAccounts {

    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $true)][string]$Username,
        [Parameter(Mandatory = $true)][string]$Domain,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][Int32]$NumberOfDigits,
        [Parameter(Mandatory = $true)][Int32]$NumberOfAccounts
    )

    begin {
        # Set strict mode 
        Set-StrictMode -Version Latest
        Write-Log -Message "Starting $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    }

    process {
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
            Exit 1
        }


    } # process

    end {
        # Return data for the function
        Write-Log -Message "Finishing $($PSCmdlet.MyInvocation.MyCommand.Name)" -Level Info
    } # end

}
