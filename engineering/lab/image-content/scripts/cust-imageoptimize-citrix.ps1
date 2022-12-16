Write-Host "=====  Executing Citrix Optimizer" -ForegroundColor "Green"

Set-ExecutionPolicy Bypass -Force

Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue

$BuildSource = "C:\deployment"
$CustomSource = "$BuildSource\custom"

$OptimizerRoot = "C:\Tools"
$OptimizerHome  = "C:\Tools\CitrixOptimizer"
$OptimizerSource = "CitrixOptimizerTool.zip"

If (!(Test-Path -Path $OptimizerRoot)) {
	New-Item -Path $OptimizerRoot -ItemType Directory -Force | Out-Null
}

Write-Host "Extracting Archive to $($OptimizerHome)" -ForegroundColor Cyan
Expand-Archive -Path ($CustomSource + "\" + $OptimizerSource) -DestinationPath $OptimizerHome -Force

#//  Remove execution if using BIS-F
& "$OptimizerHome\CtxOptimizerEngine.ps1" -mode Execute
