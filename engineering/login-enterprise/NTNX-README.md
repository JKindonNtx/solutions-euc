# About
Automation Toolkit around Login Enterprise (LE) and VMware/Citrix to fully automate test execution.
Adjusted to run on AHV.
Will take care of:
* Creating Accounts in LE and AD
* Creating/Updating Test settings in LE
* Creating Desktop Pool
* Starting Test
* Export VM and VMHost Performance Metrics to Excel
* Export LE Measurements to Excel

# Getting Started
* Install the required modules
* Create Launchers
* Copy the ExampleConfig-CitrixOnPrem-AHV.jsonc and modify the values according to your test environment
* Run the script appropriate for your environment, e.g.:
```powershell
.\CitrixVAD-AHV.ps1 -ConfigFile Config-CitrixOnPrem-AHV.jsonc

# Requirements
* Use Powershell 5.1. Powershell 6 or higher does not support Citrix snappins
* Install Citrix Cloud Powershell SDK
* Run the scripts from a Windows domain member.
* Install-Module ImportExcel
