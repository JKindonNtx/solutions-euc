Write-Host "=====  Executing Citrix Optimizer" -ForegroundColor "Green"

Set-ExecutionPolicy Bypass -Force

Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue

$BuildSource = "C:\deployment"
$CustomSource = "$BuildSource\custom\"

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
#Use 3rd Party Optimizations
# Invoke-WebRequest -Uri "https://raw.githubusercontent.com/j81blog/Citrix_Optimizer_Community_Template_Marketplace/master/templates/John%20Billekens/JohnBillekens_3rd_Party_Components.xml" -UseBasicParsing -OutFile "$OptimizerHome\Templates\JohnBillekens_3rd_Party_Components.xml"
#//  Remove execution if using BIS-F
# & "$OptimizerHome\CtxOptimizerEngine.ps1" -Template "$OptimizerHome\Templates\JohnBillekens_3rd_Party_Components.xml" -mode Execute 
