function New-LEAccounts {
    <#
    .SYNOPSIS
    Creates new LE Accounts

    .DESCRIPTION
    Creates new LE Accounts

    .PARAMETER username
    Description of each parameter being passed into the function.

    .PARAMETER domain

    .PARAMETER password

    .PARAMETER NumberOfDigits

    .PARAMETER NumberOfAccounts

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    What the function returns.

    .EXAMPLE
    PS> function-template -parameter "parameter detail"
    Description of the example.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/function-template.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.LE

#>
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
