# Load all the module scripts
foreach ($ps1 in Get-ChildItem -Recurse $PSScriptRoot\src\*.ps1) {
    . $ps1.FullName
}
