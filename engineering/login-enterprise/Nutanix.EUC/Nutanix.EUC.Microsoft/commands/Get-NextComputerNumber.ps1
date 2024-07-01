function Get-NextComputerNumber(){

    param(
        $CurrentVMs,
        $NamingConvention
    )

    try {
        $CurrentVmCount = $CurrentVms | Measure-Object
        If ($CurrentVmCount.Count = 0) {
            $var_Start_Index = "1"
        } else {
            $LastVM = $CurrentVms[$CurrentVmCount.count - 1]
            $Position = $NamingConvention.IndexOf("#")
            $NumberCount =([regex]::Matches($NamingConvention, "#" )).count
            $LastNumber = $LastVM.Substring($Position, $NumberCount)
            $NumberInt = [int]$LastNumber
            $NumberInt++
            $var_Start_Index = [string]$NumberInt
        }
    } catch {

        Write-Log -Message $_ -Level Error
        Break
    }

    return $var_Start_Index
}