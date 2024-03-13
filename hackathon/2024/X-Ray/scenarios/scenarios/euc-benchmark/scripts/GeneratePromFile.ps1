Param(
    $Action,
    $Time
)

$FilePath = "c:\scripts\$($Action).prom"

Set-Content -Path $FilePath -Encoding Ascii -NoNewline -Value "" -Force
Add-Content -Path $FilePath -Encoding Ascii -NoNewline -Value "# HELP $($Action)`n"
Add-Content -Path $FilePath -Encoding Ascii -NoNewline -Value "# TYPE $($Action) gauge`n"
if($Action -eq "SessionCounter"){
    Add-Content -Path $FilePath -Encoding Ascii -NoNewline -Value "$($Action) $($Time)`n"
} else {
    $StartSeconds = ([timespan]::parse($Time)).TotalSeconds
    Add-Content -Path $FilePath -Encoding Ascii -NoNewline -Value "$($Action) $($StartSeconds)`n"
}
Move-item -Path $FilePath -destination "C:\Program Files\windows_exporter\textfile_inputs" -force

