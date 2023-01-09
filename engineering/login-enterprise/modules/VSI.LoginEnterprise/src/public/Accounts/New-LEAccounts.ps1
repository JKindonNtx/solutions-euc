function New-LEAccounts {
    Param (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        [Parameter(Mandatory = $true)]
        [string]$Domain,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [Int32]$NumberOfDigits,
        [Parameter(Mandatory = $true)]
        [Int32]$NumberOfAccounts
    )
    
    $ExistingAccounts = Get-LEAccounts | Where-Object { $_.username -like "$($Username)*" -and $_.domain -eq $domain }
    If ($null -ne $ExistingAccounts) {
        Remove-LEAccounts -ids ($ExistingAccounts | Select-Object -ExpandProperty id) | Out-Null
    }

    Write-Log "Creating LE accounts for $Username"

    $Body = @{
        numberOfDigits   = $NumberOfDigits
        numberOfAccounts = $numberOfAccounts
        username         = $username
        domain           = $domain
        password         = $password
    } | ConvertTo-Json

    $Response = Invoke-PublicApiMethod -Method "POST" -Path 'v6/accounts/bulk' -Body $Body
    $Response.idList
    <#
    $idList = @()
    for ($i = 1; $i -le $NumberOfAccounts; $i++) {
        $newUser = "$Username{0:D$NumberOfDigits}" -f $i
        $idList += New-LEAccount -Username $newUser -Domain $Domain -Password $password
    }
    return $idList
    #>
}