. $Env:WinDir\Microsoft.Net\Framework\v4.0.30319\ngen.exe Update
If ($(Test-Path $Env:WinDir\Microsoft.Net\Framework64\v4.0.30319\ngen.exe) -eq $True) {
    . $Env:WinDir\Microsoft.Net\Framework64\v4.0.30319\ngen.exe Update;

}