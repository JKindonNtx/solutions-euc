## Run 7Zip benchmark
## author: Sven Huisman
## version 1.0
$scriptend = $true
$sleeptime = Get-Random -Minimum 10 -Maximum 60
Start-sleep $sleeptime
Start-Process -Filepath "C:\TaskT\Release\TaskT.exe" -ArgumentList "C:\Scripts\VMworkload.xml" -Wait

    #$7zipscore = cmd /c "c:\program files\7-zip\7z.exe" b -mmt1
    #$7zipresult = (((($7zipscore | select -last 1) -replace 'Tot:','').trim()) -replace '\s+',',').split(",")
    #Set-Content -Path '7zipbenchmark.prom' -Encoding Ascii -NoNewline -Value ""
    #Add-Content -Path '7zipbenchmark.prom' -Encoding Ascii -NoNewline -Value "# HELP zip_benchmark`n"
    #Add-Content -Path '7zipbenchmark.prom' -Encoding Ascii -NoNewline -Value "# TYPE zip_benchmark gauge`n"
    #Add-Content -Path '7zipbenchmark.prom' -Encoding Ascii -NoNewline -Value "zip_benchmark{score=""usage_perct""} $( $7zipresult[0] )`n"
    #Add-Content -Path '7zipbenchmark.prom' -Encoding Ascii -NoNewline -Value "zip_benchmark{score=""ru_mips""} $( $7zipresult[1] )`n"
    #Add-Content -Path '7zipbenchmark.prom' -Encoding Ascii -NoNewline -Value "zip_benchmark{score=""rating_mips""} $( $7zipresult[2] )`n"
    #Move-item -Path '7zipbenchmark.prom' -destination 'C:\Program Files\windows_exporter\textfile_inputs\7zipbenchmark.prom' -force
    #Start-Sleep -seconds 60
    # Remove-Item -Path 'C:\Program Files\windows_exporter\textfile_inputs\7zipbenchmark.prom' -force

