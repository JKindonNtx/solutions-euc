Param(
     [Parameter(Mandatory = $True)]
     [ValidateSet("Export","Import")]
     $Mode,
     
     [Parameter(Mandatory = $True)]
     [ValidateSet("1912_LTSR","2203_LTSR","CR")]
     $BuildVersion,

     [Parameter(Mandatory = $False)]
     #$PolicyDataLocation = "\\10.57.64.39\MDTLoginVSI$\Applications\CitrixPolicyStore\$BuildVersion",
     $PolicyDataLocation = "\\ws-files.wsperf.nutanix.com\Automation\Apps\Citrix\CitrixPolicyStore\$BuildVersion",

     [Parameter(Mandatory = $False)]
     $PolicyDataFile = "SitePolicySet.txt"
 )


if ($Mode -eq "Export") {
    if (!(Test-Path $PolicyDataLocation)){ New-Item -Path $PolicyDataLocation -ItemType Directory -Force | Out-Null }
    Add-PSSnapin Citrix*
    Export-BrokerDesktopPolicy | Out-File "$PolicyDataLocation\$PolicyDataFile" -Force
}

if ($Mode -eq "Import") {
    if (!(Test-Path $PolicyDataLocation)){ Write-Warning "No source files detected. Exit Script"; Exit 1 }
    Add-PSSnapin Citrix*
    Import-BrokerDesktopPolicy (Get-Content "$PolicyDataLocation\$PolicyDataFile")
}
