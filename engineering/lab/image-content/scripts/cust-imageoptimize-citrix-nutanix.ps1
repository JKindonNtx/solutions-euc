Write-Host "=====  Executing Citrix Optimizer Nutanix Defaults" -ForegroundColor "Green"

Set-ExecutionPolicy Bypass -Force

Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue

$BuildSource = "C:\deployment"
$CustomSource = "$BuildSource\custom"

$OptimizerHome  = "C:\Tools\CitrixOptimizer"

# Run Nutanix Optimizations
& "$OptimizerHome\CtxOptimizerEngine.ps1" -Template "$CustomSource\Solutions_EUC_Nutanix.xml" -mode Execute 