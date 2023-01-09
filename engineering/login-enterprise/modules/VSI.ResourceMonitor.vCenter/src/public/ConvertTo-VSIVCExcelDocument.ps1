function ConvertTo-VSIVCExcelDocument {
    param(
        $SourceFolder,
        $OutputFile
    )

    Foreach ($csv in (Get-ChildItem "$($SourceFolder)\*.csv")) {
        Import-Csv -Path $csv.FullName | Export-Excel -Append -WorksheetName $CSV.BaseName -Path $OutputFile
    }
}