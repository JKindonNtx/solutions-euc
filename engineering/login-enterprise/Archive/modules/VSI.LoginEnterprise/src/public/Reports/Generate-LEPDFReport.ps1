function Export-LEPDFReport {
    Param(
        $XLSXFile,
        $ReportConfigurationFile
    )
    $ReportConfigurationFile = (Get-Item $ReportConfigurationFile).FullName
    Set-Content -Path $env:temp\Configuration.jsonc -Value ([IO.File]::ReadAllText($ReportConfigurationFile) -replace "`r`n", "`n");
    Invoke-PublicApiMethod -Path "v6-preview/labs/reports/config" -Form @{file = Get-Item $env:temp\Configuration.jsonc } -Method POST
    $XLSXFile = Get-Item $XLSXFile
    $ReportId = Invoke-PublicApiMethod -Path "v6-preview/labs/reports/generate" -Form @{file = $XLSXFile } -Method POST
    $State = Invoke-PublicApiMethod -Path "v6-preview/labs/reports/$ReportId/state" 
    while ($state.isDone -ne $true) {
        $State = Invoke-PublicApiMethod -Path "v6-preview/labs/reports/$ReportId/state" 
        Start-Sleep -Seconds 10
    }
    if ($state.state -eq "Done") {
        $OutputFile = "$(Split-Path $XLSXFile.FullName -Parent)\$($XLSXFile.BaseName).pdf"
        if (Test-Path $OutputFile) { Remove-Item $OutputFile -Force }
        Invoke-PublicApiMethod -Path "v6-preview/labs/reports/$ReportId/download" -OutFile $OutputFile
    } else {
        Write-Warning "Report generation failed with state: $($state.state)"
    }
}