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

# Original Login Enterprise info

# Getting Started
* Install the required modules
* Copy the ExampleConfig.jsonc and modify the values according to your test environment
* Run the script appropriate for your environment, e.g. HorizonView:
```powershell
.\HorizonView.ps1 -ConfigFile MyConfig.jsonc
```
# Configuration
The configuration is stored in a jsonc file, with an option to override settings via environment variables and/or via commandline arguments  
Inside the config file it's possible to use the value of another configuration item by refering to it's name
e.g.
```jsonc
"Domain": {
        "NetBios": "EXAMPLE",
        "LDAPPath": "LDAP://DC=example,DC=loginvsi,DC=com",
        "LDAPUsername": "",
        "LDAPPassword": ""
    },
    "Users": {
        "BaseName": "testUsers",
        "GroupName": "${Users.BaseName}", // This will resolve to "testUsers" value above
        "Password": "SuperSecurePassword!123",
        "NetBios": "${Domain.NetBios}", // This will resolve to "EXAMPLE" value above
        "OU": "OU=TestUsers",
        "NumberOfDigits": 3
    }
```
When overriding values via environment variables, be sure to use the VSI_prefix and underscores instead of the dot.
## Performance Metrics
The performance metrics gathered from vCenter are configured in the vCenterCounters.jsonc file. This also contains a list of VMNames to exlcude from monitoring. Modify this to exclude for example springPath storage VM's that are part of a Cisco HyperFlex deployment.  
An alternative metrics config file path can be supplied via the commandline, see the example below.
## Examples
```powershell
# Standard usage, with all settings supplied via config file
.\HorizonView.ps1 -ConfigFile MyConfig.jsonc
# Override Users.NumberOfDigits setting via env var
$env:VSI_USERS_NUMBEROFDIGITS = 6
.\HorizonView.ps1 -ConfigFile MyConfig.jsonc
# Specify a different set of vCenterCounters that you want to export
.\HorizonView.ps1 -ConfigFile MyConfig.jsonc -vCenterCounterConfigFile MyvCenterCounterConfig.jsonc
```
## Requirements VMware Horizon View
```powershell 
Install-Module VMware.PowerCLI
Install-Module ImportExcel
```

## Requirements CitrixCloud
* Install Citrix Cloud Powershell SDK
* A trust needs to exist between the machine running the scrits and the domain where the VM's and users will be created. The ctx account creation via powershell uses impersonation, that only works if there's a trust.
* Currently only CTX Cloud with vSphere on-prem configuration (MCS) is supported
```powershell 
Install-Module ImportExcel
```

# Changelog
* v.0.1.0 - Initial version