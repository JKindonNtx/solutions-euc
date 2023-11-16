Set-StrictMode -Version 3.0

# Load all root files
"commands" | ForEach-Object {
   Get-ChildItem -Path (Join-Path $PSScriptRoot $_) -Filter '*.ps1' | ForEach-Object {
      $pathToFile = $_.FullName
      try {
         . $pathToFile
      } catch {
         Write-Error -Message "Failed to import file $($pathToFile): $_"
      }
   }
}