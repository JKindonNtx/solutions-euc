Write-Host "=====  Tattoo Image" -ForegroundColor "Green"

Set-ExecutionPolicy Bypass -Force

# Create Tatoo Registry Key
New-Item -Path HKLM:\Software -Name BuildTatoo -Force

# Get Operating System Details
$OSDetails = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion"

if($OsDetails.ProductName -like "Windows Server 2022*") { $OSName = "Windows Server 2022" }
if($OsDetails.ProductName -like "Windows Server 2019*") { $OSName = "Windows Server 2019" }
if($OsDetails.ProductName -like "Windows 10*") { $OSName = "Windows 10" }
if($OsDetails.ProductName -like "Windows 11*") { $OSName = "Windows 11" }

$OSVersion = $($OSDetails.DisplayVersion) + "-" + $($OSDetails.CurrentBuildNumber) + "." + $($OSDetails.UBR)

New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "OSName" -Value $OSName -Force
New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "OSVersion" -Value $OSVersion -Force

# Get Office Version
$x32 = ${env:ProgramFiles(x86)} + "\Microsoft Office"
$x64 = $env:ProgramFiles + "\Microsoft Office"

if (Test-Path -Path $x32) {$Excel32 = Get-ChildItem -Recurse -Path $x32 -Filter "EXCEL.EXE"; $Version = "x32"}
if (Test-Path -Path $x64) {$Excel64 = Get-ChildItem -Recurse -Path $x64 -Filter "EXCEL.EXE"; $Version = "x64"}
if ($Excel32) {$Excel = $Excel32}
if ($Excel64) {$Excel = $Excel64}

$DisplayVersion = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -Name "DisplayVersion" -ErrorAction SilentlyContinue | Where-Object {$_.DisplayVersion -eq $Excel.VersionInfo.ProductVersion -and $_.PSChildName -notlike "{*}"}
$Office = Get-ItemProperty -Path $DisplayVersion.PSPath
$Office | ForEach-Object {"Product: " + $_.DisplayName + $(if ($_.InstallLocation -eq $x32) {", 32 Bit"} else {", 64 Bit"})  + ", Productversion: " + $_.PSChildName + ", Build: " + $_.DisplayVersion}

$StrippedOfficeName = ($Office.DisplayName).Split("-")
$DisplayName = $StrippedOfficeName[0] + $Version

New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "OfficeVersion" -Value $Office.DisplayVersion -Force
New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "OfficeName" -Value $DisplayName -Force

# Get Optimiser Details
if(Test-Path -Path "C:\OSOT"){
    $VMwareOSOT = Get-ChildItem -Recurse -Path "C:\OSOT" -Filter "VMwareOSOptimizationTool.EXE"
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "Optimizer" -Value "VMware Optimizer"
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "OptimizerVersion" -Value $VMwareOSOT.VersionInfo.ProductVersion
} else {
    $CO = Get-ChildItem -Recurse -Path "C:\Tools\CitrixOptimizer" -Filter "CitrixOptimizerTool.EXE"
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "Optimizer" -Value "Citrix Optimizer"
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "OptimizerVersion" -Value $CO.VersionInfo.ProductVersion
}

# Get VDA Version
if(Test-Path -Path "C:\Program Files\CITRIX") {
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "VdaType" -Value "Citrix"
    $VDA = Get-Package | Where-Object {$_.Name -like "Citrix Virtual Apps and Desktops*" }
    $VdaName = ($VDA.Name).Split("-")
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "VdaName" -Value $VdaName[0]
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "VdaVersion" -Value $VDA.Version
} else {
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "VdaType" -Value "VMware"
    $VDA = Get-Package | Where-Object {$_.Name -like "VMware Horizon*" }
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "VdaName" -Value $VDA.Name
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "VdaVersion" -Value $VDA.Version
}

# Get Guest Tools Version
if(Test-Path -Path "C:\Program Files\VMware") {
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "HvType" -Value "VMware"
    $GuestTools = Get-Package | Where-Object {$_.Name -like "VMware*" }
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "GuestTools" -Value $GuestTools.Name
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "GuestToolsVersion" -Value $GuestTools.Version
} else {
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "HvType" -Value "AHV"
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "GuestTools" -Value "AHV"
    New-ItemProperty -Path "HKLM:\Software\BuildTatoo" -Name "GuestToolsVersion" -Value "0"
}