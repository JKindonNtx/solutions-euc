function Write-Good {

    param
    (
        $Message
    )

    $DateTime = Get-Date -Format "MM/dd/yyyy - HH:mm:ss"
    write-host "[$($DateTime)] $($Message)" -ForegroundColor Green
}