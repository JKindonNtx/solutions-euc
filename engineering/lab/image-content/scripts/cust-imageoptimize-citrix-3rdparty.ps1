Write-Host "=====  Executing Citrix Optimizer - 3rd Party Apps Template" -ForegroundColor "Green"

Set-ExecutionPolicy Bypass -Force

Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue

$OptimizerHome  = "C:\Tools\CitrixOptimizer"

#Use 3rd Party Optimizations
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/j81blog/Citrix_Optimizer_Community_Template_Marketplace/master/templates/John%20Billekens/JohnBillekens_3rd_Party_Components.xml" -UseBasicParsing -OutFile "$OptimizerHome\Templates\JohnBillekens_3rd_Party_Components.xml"
#//  Remove execution if using BIS-F
& "$OptimizerHome\CtxOptimizerEngine.ps1" -Template "$OptimizerHome\Templates\JohnBillekens_3rd_Party_Components.xml" -mode Execute 
