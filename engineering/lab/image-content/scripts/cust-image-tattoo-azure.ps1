Write-Host "=====  Tattoo Image" -ForegroundColor "Green"

Set-ExecutionPolicy Bypass -Force

# Create Tattoo Registry Key
New-Item -Path HKLM:\Software -Name BuildTattoo -Force

# Get Operating System Details
$OSDetailName = (Get-WmiObject -class Win32_OperatingSystem).Caption

if($OSDetailName -like "*Windows Server 2022*") { $OSName = "Windows Server 2022" }
if($OSDetailName -like "*Windows Server 2019*") { $OSName = "Windows Server 2019" }
if($OSDetailName -like "*Windows 10*") { $OSName = "Windows 10" }
if($OSDetailName -like "*Windows 11*") { $OSName = "Windows 11" }

$OSDetails = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion"
$OSVersion = $($OSDetails.DisplayVersion) + "-" + $($OSDetails.CurrentBuildNumber) + "." + $($OSDetails.UBR)

New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "TargetOS" -Value $OSName -Force
New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "TargetOSVersion" -Value $OSVersion -Force

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

#New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OfficeVersion" -Value $Office.DisplayVersion -Force
#New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OfficeName" -Value $DisplayName -Force
New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OfficeVersion" -Value $DisplayName -Force

# Get Optimiser Details
if(Test-Path -Path "C:\OSOT"){
    $VMwareOSOT = Get-ChildItem -Recurse -Path "C:\OSOT" -Filter "VMwareOSOptimizationTool.EXE"
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OptimizerVendor" -Value "VMware Optimizer" -Force
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OptimizationsVersion" -Value $VMwareOSOT.VersionInfo.ProductVersion -Force
} else {
    if(Test-Path -Path "C:\Tools\CitrixOptimizer"){
        $CO = Get-ChildItem -Recurse -Path "C:\Tools\CitrixOptimizer" -Filter "CitrixOptimizerTool.EXE"
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OptimizerVendor" -Value "Citrix Optimizer" -Force
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OptimizationsVersion" -Value $CO.VersionInfo.ProductVersion -Force
    } else {
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OptimizerVendor" -Value "None" -Force
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "OptimizationsVersion" -Value "N/A" -Force
    }
}

# Get VDA Version
if(Test-Path -Path "C:\Program Files\CITRIX") {
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "VdaType" -Value "Citrix" -Force
    $VDA = Get-Package | Where-Object {$_.Name -like "Citrix Virtual Apps and Desktops*" }
    $VdaName = ($VDA.Name).Split("-")
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "VdaName" -Value $VdaName[0] -Force
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "DesktopBrokerAgentVersion" -Value $VDA.Version -Force
} else {
    if(Test-Path -Path "C:\Program Files (x86)\Parallels\ApplicationServer") {
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "VdaType" -Value "RAS" -Force
        $VDA = Get-Package | Where-Object {$_.Name -like "Parallels Remote Application*" }
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "VdaName" -Value $VDA.Name -Force
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "DesktopBrokerAgentVersion" -Value $VDA.Version -Force
    } else {
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "VdaType" -Value "VMware" -Force
        $VDA = Get-Package | Where-Object {$_.Name -like "VMware Horizon*" }
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "VdaName" -Value $VDA.Name -Force
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "DesktopBrokerAgentVersion" -Value $VDA.Version -Force
    }
}

# Get Guest Tools Version
if(Test-Path -Path "C:\Program Files\VMware") {
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "HvType" -Value "VMware" -Force
    $GuestTools = Get-Package | Where-Object {$_.Name -like "VMware Tools*" }
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "GuestTools" -Value $GuestTools.Name -Force
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "ToolsGuestVersion" -Value $GuestTools.Version -Force
} else {
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "HvType" -Value "AHV" -Force
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "GuestTools" -Value "AHV" -Force
    New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "ToolsGuestVersion" -Value "0" -Force
}

#Azure

#Check if the Azure metadata service endpoint is accessible
$metadataEndpoint = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/instance?api-version=2020-09-01" -Method Get -Headers @{ "Metadata" = "true" } -ErrorAction SilentlyContinue

# Check if the VM is an Azure VM based on the presence of the metadata endpoint
if ($metadataEndpoint) {
    Write-Output "The VM is an Azure VM."
    $VMSpec = Invoke-RestMethod -Headers @{"Metadata"="true"} -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | ConvertTo-Json -Depth 64 | ConvertFrom-Json

    # CPU Spec
    $cpuInfo = Get-WmiObject -Class Win32_Processor

    # Memory Spec
    $memoryInfo = Get-WmiObject -Class Win32_PhysicalMemory

    # Network Adapter
    $networkAdapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    $AcceleratedNetworkingAdapter = $networkAdapter | Where-Object { $_.InterfaceDescription -like "*Mellanox Connectx*"}
    if ($AcceleratedNetworkingAdapter) {
        $AcceleratedNetworking = $true
    } else {
        $AcceleratedNetworking = $false
    }

    # Page File Details
    $pageFileLocation = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name PagingFiles
    $PageFile = $pageFileLocation.PagingFiles -replace '.*?(.*:\\PageFile\.sys).*', '$1'

    # Disk Info
    $diskInfo = Get-WmiObject -Class Win32_DiskDrive
    $TempDisk = $diskInfo | Where-Object {$_.Partitions -ne 3}
    $TempDiskSize  = [math]::Round($TempDisk.Size / 1GB, 2)

    $AdditionalVMSpec = Get-ComputerInfo

    # DeviceGuard Configuration (Credential Guard)
    if (($AdditionalVMSpec.DeviceGuardSecurityServicesConfigured) -match 'CredentialGuard') {
        $CredentialGuard = $true
    } else {
        $CredentialGuard = $false
    }

    $vm_properties = @{
        VM_Name                  = $VMSpec.compute.name
        VM_Location              = $VMSpec.compute.location
        VM_Offer                 = $VMSpec.compute.offer
        VM_secureBoot            = $VMSpec.compute.securityProfile.SecureBootEnabled
        VM_vTPM                  = $VMSpec.compute.securityProfile.virtualTpmEnabled
        VM_Size                  = $VMSpec.compute.vmSize
        VM_Credential_Guard      = $CredentialGuard
        VM_Bios_Name             = $AdditionalVMSpec.BiosName
        
        VM_CPU_Name              = $cpuInfo.Name
        VM_CPU_Manufacturer      = $cpuInfo.Manufacturer
        VM_CPU_ClockSpeed        = $cpuInfo.MaxClockSpeed
        VM_CPU_Caption           = $cpuInfo.Caption
        VM_CPU_Cores             = $cpuInfo.NumberOfCores
        VM_CPU_LogicalProcs      = $cpuInfo.NumberOfLogicalProcessors
        VM_CPU_ThreadCount       = $cpuInfo.ThreadCount

        VM_Memory_Size           = ($memoryInfo | Measure-Object -Property Capacity -Sum).Sum / 1GB

        VM_AcceleratedNetworking = $AcceleratedNetworking

        VM_pageFile              = $PageFile
        
        OS_Type                  = $VMSpec.compute.osType
        OS_Offer                 = $VMSpec.compute.storageProfile.imageReference.offer
        OS_Deployed_Version      = $VMSpec.compute.storageProfile.imageReference.version
        OS_Deployed_Sku          = $VMSpec.compute.storageProfile.imageReference.sku
        OS_Running_Version       = $VMSpec.compute.version
        
        Disk_Type                = $VMSpec.compute.storageProfile.osDisk.managedDisk.storageAccountType
        Disk_Size                = $VMSpec.compute.storageProfile.osDisk.diskSizeGB
        Disk_Caching             = $VMSpec.compute.storageProfile.osDisk.caching
        Disk_Encryption          = $VMSpec.compute.storageProfile.osDisk.encryptionSettings.Enabled
        Disk_Write_Accelerator   = $VMSpec.compute.storageProfile.osDisk.writeAcceleratorEnabled

        Disk_TempDisk_Size       = $TempDiskSize
    }

    foreach ($Item in $vm_properties.GetEnumerator() | Sort-Object -Property Key -Descending) {
        New-ItemProperty -Path "HKLM:\Software\BuildTattoo" -Name "Azure_$($Item.Key)" -Value $($Item.Value) -Force
    }

} else {
    Write-Output "The VM is not an Azure VM."
}

