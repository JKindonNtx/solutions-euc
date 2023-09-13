function Write-Progress {

    param
    (
        $Message,
        [switch]$Update
    )

    $DateTime = Get-Date -Format "MM/dd/yyyy - HH:mm:ss"
    if($Update){
        write-host "`r[$($DateTime)] $($Message)" -NoNewLine
    } else {
        write-host "[$($DateTime)] $($Message)"
    }
    
}