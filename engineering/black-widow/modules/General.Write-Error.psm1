function Write-Error {

    param
    (
        $Message
    )

    $DateTime = Get-Date -Format "MM/dd/yyyy - HH:mm:ss"
    write-host "[$($DateTime)] $($Message)" -ForegroundColor Red
}