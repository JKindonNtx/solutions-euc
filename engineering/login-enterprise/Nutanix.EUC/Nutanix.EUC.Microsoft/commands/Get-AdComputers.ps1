function Get-AdComputers(){

    param(
        [string] $filter
    )

    try {
        $SearchFilter = "$($filter)*"
        $AdComputers = Get-ADComputer -Filter {Name -like $SearchFilter } | Sort-Object -Property Name
    } catch {

        Write-Log -Message $_ -Level Error
        Break
    }

    return $AdComputers
}