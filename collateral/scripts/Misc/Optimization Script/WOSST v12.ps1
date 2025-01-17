############################################################################################################################
#
#												Created by
#												Jake Norman
#									         Nutanix Senior Consultant
#
#										    Use at your own peril
#									   No warranties or support will be provided
#
#							   Please comment out any section/line that you do not want
#
############################################################################################################################

#region Change Log
<#
						Change Log

					v.01	Operating System Optimizations
		4/30/21		v.02	Corrected double quote mismatches
							Added more context to script sections for easy identification
							Added Application Optimization Section including template
								Google Chrome
								Microsoft Edge Chromium
								Adobe Reader DC
		5/3/21		v.03	Changed Application Installed Query syntax
							Added more Application Optimizations
								Mozilla Firefox
								Java Runtime Environment
								Microsoft Edge Chromium
		5/5/21		v.04		Changed Microsoft Store uninstallation
							Changed Services to Array methodology
							Added Autologger Disabling
							Added Reboot to end of script
		5/7/21		v.05	Changed Versioning
							Added Display Name Description to Services
							Added Windows Optional Features Disabling, with a description of each optional feature
							Added some much needed error checking for Generic VDI registry key additions section
							Additional Scheduled Tasks optimized
							Added more Application Optimizations
								Microsoft OneDrive
							Changed Reboot Methodology (Disabled by Default)
		5/18/21 	v.06	Optimized Microsoft.XboxGameOverlay AppxPackage (Different from Microsoft.XboxGamingOverlay)
							Added more Application Optimizations
								Microsoft Teams
							Additional Services optimized
							Added Graphical Interface option for Provisioned Appx Packages removal (Disabled by Default)
							Added Graphical Interface option for Disabling Services (Disabled by Default)
							Added Graphical Interface option for Disabling Scheduled Tasks (Disabled by Default)
							Changed Scheduled Tasks to Array methodology
							More clarification between sections
							More clarification for documentation vs. script
		5/27/21 	v.07	Added Logging Output to File for Script
							Corrected Decision Tree for Services Optimization
							Corrected Google Chrome Application Optimzation syntax & location errors
							Corrected syntax error for Recovery Partition Removal
		6/17/21 	v.08	Added Microsoft Update Health Service Optimization
							Overall, Section, and Sub-Section Progress Bars added
		6/30/21 	v.09	In ForEach Loop Progress Bars added
							Start-Transcript used to capture additional logging information, including non-terminating error logging
							Script & Syntax Cleanup
							Local File Cleanup Methodology changed
							Frame specific exclusions added to Local File Cleanup
							Fixed location for logging for Frame FGA
		7/6/21		v.10	Defrag Disabled by Default, with explanations as to WHEN to use it and WHY you don't
							Small Syntax changes to some Arrays
							Additional Services optimized (48)
							Additional Scheduled Tasks optimized (2)
							Additional UWP applications optimized (4)
							Added Generic VDI optimizations (3)
							Added 32bit NGEN Updates
							Added Execution of Queued Items for both 32bit and 64bit NGEN Updates
		7/8/21		v.10.1	Removed and Warned against disabling the Connected Devices Platform Service
		7/19/21		v.10.2	Removed and Warned against disabling the Capability Access Manager Service
		7/27/21		v.11	Entire script consolidation
							Addition of Regions to allow easier PowerShell ISE section management
							Syntax and Script flow corrections
							Change Active Setup to Array Methodology
							Restructure of methodology, naming, placement and ID numbering of Write-Progress bars
							Adding Microsoft Edge First Run Experience Optimization
							Added Known Issues List
		10/21/21	v.11.1	Changes to Services for Network Connection Broker to address issue Ops004
							Changed Logging If/Then to address issue Ops001
							Found and disabled Service (ClipSVC) that caused issue Ops003
							Corrected math syntax for Generic VDI Optimizations progress bars
		3/3/22		v.12	Syntax Changes to Functions
							Logging Changes:
								Single log location that is agnostic of environment
								Log file name now contains date/time format
							Revert Actions Preparation:
								Script will capture current status of Services, Scheduled Tasks, Active Setup,
								Autologgers and Optional Features and place them as registry values under
								HKLM:\SOFTWARE\Nutanix\WOSTT for future use.
									Services section now captures current Service StartupType
									Active Setup section now captures current Stubpath information
									Scheduled Tasks section now captures current Task Start setting
									Autologger section now captures current Start setting
									Optional Features section now captures current Feature State setting
							Active Setup coding reworked to allow for Revert Actions to work
							Scheduled Tasks coding reworked to allow for Revert Actions to work
							Additional Optional Features Disabled
							RebootRequiredStatus variable added for future use
							EndRegions now contain region information for easier script location determination
							Added Verbose logging to key actions for Transcript Logging purposes
							StopWatch added to script that outputs script runtime to Transcript
							Added --- line breaks to the Transcript for easier identification of actions
							Minor spelling and syntax corrections
#>
#endregion Change Log

#region Known Issues List
<#
		Date Identified		Version Identified		Version Fixed		Issue Id		Priority		Description of Issue	
		7/27/21				v.11					v.11.1				Ops001			High			Logging location doesn't account for MF2 upgraded to FGA and defaults logs to MF2 location.
		7/27/21				v.11										Ops002			Low				PowerShell language for the removal of the Recovery Partition doesn't work on Server 2016.
		8/23/21				v.11					v.11.1				Ops003			High			Script causing periodic Sysprep issues, breaking the image for Frame DJI.
		8/30/21				v.11					v.11.1				Ops004			Medium			Disabling the CDPS Service prior to active user account will cause the Display Settings module of SystemSettings.exe to crash.
																										CDPS is dependency of Network Connection Broker.
		8/30/21				v.11					v.11.1				Ops005			Medium			Disabling App Readiness service prior to active user account can cause issues with UWP Applications and Windows Updates that require a reboot.
#>
#endregion Known Issues List

Set-ExecutionPolicy Unrestricted -Force

#region Start Script Timer

$ScriptStopWatch = [System.Diagnostics.Stopwatch]::StartNew()

$ScriptStopWatch.Start() 

#endregion Start Script Timer

#region Reboot Required Status

$RebootRequiredStatus = "False"

#endregion Reboot Required Status

#region Functions
<#
	Funtions Only
	In This
	Section
#>

Function Get-TimeStamp
{
	return "({0:MM-dd-yy} {0:HH-mm-ss})" -f (Get-Date)
}

<#
	End of Functions
#>
#endregion Functions

#region Logging Setup

$LogFile = "WOSTT $(Get-TimeStamp).log"

$RootLocation = "$env:programdata\WindowsOptimizations\"

$LogFileLocation = $RootLocation + "Log\"

$Log = $LogFileLocation + $LogFile

Write-Output "Logging set to $LogFileLocation"

If (-not(Test-Path -Path $LogFile)) {
    If (-not(Test-Path -Path $LogFileLocation)) {
        If (-not(Test-Path -Path $RootLocation)) {
			New-Item -Path $RootLocation -ItemType "Directory"
		}
		New-Item -Path $LogFileLocation -ItemType "Directory"
	}
    New-Item -Path $LogFileLocation -Name $LogFile -ItemType "File" -Value "$(Get-TimeStamp)            Starting Windows Operating System Tuning Tool Logging`n"
}
Else {
    If (-not(Test-Path -Path "$env:programdata\WindowsOptimizations")) {
		New-Item -Path $LogFileLocation -ItemType "Directory"
		New-Item -Path $LogFileLocation -Name $LogFile -ItemType "File" -Value "$(Get-TimeStamp)            Starting Windows Operating System Tuning Tool Logging`n"
	}
}

write-output $Log

Start-Transcript $Log -Append

#endregion Logging Setup

#region Logging for Revert Actions
<#
	Revert Actions Logging
	Setup Only In
	This Section
#>

New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\UWP Apps" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\UWP Apps\Installed" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\UWP Apps\Provisioned" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Services" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Scheduled Tasks" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Active Setup" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Active Setup\64bit" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Active Setup\32bit" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Autologger" -ErrorAction SilentlyContinue -Verbose
New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Optional Features" -ErrorAction SilentlyContinue -Verbose

<#
	End of Revert Actions Logging Setup
#>
#endregion Logging for Revert Actions

Write-Progress -Activity "Windows Optimizations" -Id 0 "Overall Progress" -PercentComplete 0

$OpsCounter = 0
$Ops = 20

#region OS Version Check
<#
	Checks the version of the OS
#>

$OSVersion = Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion"

$OSMajorVersion = $OSVersion.ProductName
$OSMinorVersion = $OSVersion.ReleaseID

"$(Get-TimeStamp)            Windows Version is $OSMajorVersion $OSMinorVersion."

#endregion OS Version Check

#region Cleanup Tool Configuration
<#
	Runs Cleanup Tool
	Sets your desired cleanup settings
#>

Write-Progress -Activity "Running Microsoft Cleanup Tool." -Id 300 -ParentId 0 -PercentComplete 0

Start-Process -Wait "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/sageset:1"

"$(Get-TimeStamp)            CleanMgr options set.  CleanMgr logs are kept at '$env:SystemRoot\System32\LogFiles\setupcln'"

Write-Progress -Activity "Running Microsoft Cleanup Tool." -Id 300 -ParentId 0 -PercentComplete 100 -Completed

$OPsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#endregion Cleanup Tool Configuration

Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete 0

$OSOpsCounter = 0
$OSOps = 7

"$(Get-TimeStamp)            Let the Optimization of $OSMajorVersion $OSMinorVersion begin."

#region UWP Application Optimizations
<#
	Uninstalls Provisioned and Installed UWP Apps
	Windows Desktop OS Only!
#>

If ($OSMajorVersion -like "*Windows 10*") {

Write-Progress -Activity "Optimizing UWP Applications" -Id 110 -ParentId 10 -PercentComplete 0

"$(Get-TimeStamp)            Optimizing $OSMajorVersion $OSMinorVersion UWP Applications."
"-----------------------------------------------------------------------"

#region List of UWP Applications

#Get-ProvisionedAppXPackage -Online|Select DisplayName

$UWPApps = @(
	"Microsoft.BingWeather",
	"Microsoft.DesktopAppInstaller",
	"Microsoft.GetHelp",
	"Microsoft.Getstarted",
	"Microsoft.Messaging",
	"Microsoft.Microsoft3DViewer",
	"Microsoft.HEIFImageExtension",
	"Microsoft.MicrosoftOfficeHub",
	"Microsoft.MicrosoftSolitaireCollection",
	"Microsoft.MicrosoftStickyNotes",
	"Microsoft.MixedReality.Portal",
	"Microsoft.MSPaint",
	"Microsoft.Office.OneNote",
	"Microsoft.OneConnect",
	"Microsoft.People",
	"Microsoft.Print3D",
	"Microsoft.ScreenSketch",
	"Microsoft.SkypeApp",
	"Microsoft.StorePurchaseApp",
	"Microsoft.Wallet",
	"Microsoft.WebMediaExtensions",
	"Microsoft.WebpImageExtension",
	"Microsoft.Windows.Photos",
	"Microsoft.WindowsAlarms",
	"Microsoft.WindowsCamera",
	"Microsoft.windowscommunicationsapps",
	"Microsoft.WindowsFeedbackHub",
	"Microsoft.WindowsMaps",
	"Microsoft.WindowsSoundRecorder",
	# (DISABLED BY DEFAULT)"Microsoft.WindowsStore", #Microsoft Store can be very hard to install again after it is removed.  Only disable If you fully understand the ramifications. https://docs.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/cannot-remove-uninstall-or-reinstall-microsoft-store-app
	"Microsoft.Xbox.TCUI",
	"Microsoft.XboxApp",
	"Microsoft.XboxGameOverlay",
	"Microsoft.XboxGamingOverlay",
	"Microsoft.XboxIdentityProvider",
	"Microsoft.XboxSpeechToTextOverlay",
	"Microsoft.YourPhone",
	"Microsoft.ZuneMusic",
	"Microsoft.ZuneVideo"
)

#endregion List of UWP Applications

#region Provisioned UWP Application Uninstallation

$UWPAppsCounter = 0

ForEach ($UWPApp in $UWPApps) {
	Get-AppXProvisionedPackage -Online -Verbose |
	where DisplayName -EQ $UWPApp |
	Remove-AppxProvisionedPackage -Online -Verbose
	"$(Get-TimeStamp)            $UWPApp UWP Provisioned Application Removed"
	"-----------------------------------------------------------------------"
	$UWPAppsCounter++
	Write-Progress -Activity "Optimizing UWP Provisioned Applications" -Id 111 -ParentId 110 -PercentComplete (($UWPAppsCounter / $UWPApps.count) * 100)
}

Write-Progress -Activity "Optimizing UWP Provisioned Applications" -Id 111 -ParentId 110 -PercentComplete 100 -Completed

#endregion Provisioned UWP Application Uninstallation

Write-Progress -Activity "Optimizing UWP Applications" -Id 110 -ParentId 0 -PercentComplete 50

#region Installed UWP Application Uninstallation

$UWPAppsCounter = 0

ForEach ($UWPApp in $UWPApps) {
	Get-AppxPackage -Name $UWPApp -AllUsers | Remove-AppxPackage -Verbose
	"$(Get-TimeStamp)            $UWPApp UWP Installed Application Removed"
	"-----------------------------------------------------------------------"
	$UWPAppsCounter++
	Write-Progress -Activity "Optimizing UWP Installed Applications" -Id 112 -ParentId 110 -PercentComplete (($UWPAppsCounter / $UWPApps.count) * 100)
}

Write-Progress -Activity "Optimizing UWP Installed Applications" -Id 112 -ParentId 110 -PercentComplete 100 -Completed

#endregion Installed UWP Application Uninstallation

Write-Progress -Activity "Optimizing UWP Applications" -Id 110 -ParentId 0 -PercentComplete 100 -Completed

}

$OSOpsCounter++
Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete (($OSOpsCounter / $OSOps) * 100)

$OPsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

<#
	If you wish to use a multi-selectable GUI to remove AppxProvisioned Packages, use the below.

	Get-AppxProvisionedPackage -Online | Out-GridView -PassThru | Remove-AppxProvisionedPackage -Online
#>

"$(Get-TimeStamp)		End Of Optimizing"
"				$OSMajorVersion $OSMinorVersion"
"				UWP Applications."
"-----------------------------------------------------------------------"

#endregion UWP Application Optimizations

#region Service Optimizations
<#
	Stops and Disables Services
	Array Methodology
#>

Write-Progress -Activity "Optimizing Windows Services" -Id 120 -ParentId 10 -PercentComplete 0

"$(Get-TimeStamp)            Optimizing $OSMajorVersion $OSMinorVersion Services."

<#
	The below Services pertain to Windows 10 and Server 2016/2019
#>

$Services = @(
	"AJRouter",											#	AllJoyn Router Service
#	DISABLED BY DEFAULT	"AppReadiness",					#	App Readiness										Do not Disable this Service.  Can cause issues with UWP Applications and Windows Updates.		Listed here for informational purposes
	"AppIDSvc",											#	Application Identity
	"ALG",												#	Application Layer Gateway Service
	"AppMgmt",											#	Application Management
#	(DISABLED BY DEFAULT) "AppXSvc",					#	Appx Deployment Service								Disable this service ONLY if you remove ALL UWP Applications					Listed here for informational purposes
	"bthserv",											#	Bluetooth Support Service
#	(DISABLED BY DEFAULT) "ClipSVC",					#	Client License Service								Disable this service ONLY if you are not Domain Joining the Workload VMs		Listed here for informational purposes
	"CloudDrive",										#	CloudDrive
#	DISABLED BY DEFAULT "CDPSvc",						#	Connected Devices Platform Service					Do not Disable this Service.  Causes issues with Display Settings window.		Listed here for informational purposes
    "DiagTrack",										#	Connected User Experiences and Telemetry			Disabling this service can potentially cause issues with Microsoft Defender ATP
	"PimIndexMaintenanceSvc*",							#	Contact Data										Service Name and Display Name change per user
	"DeviceAssociationService",							#	Device Association Service
	"DmEnrollmentSvc",									#	Device Management Enrollment Service
    "dmwappushservice",									#	Device Management Wireless Application Protocol (WAP) Push message Routing Service on Windows 10; dmwappushservice on Windows Server
	"DPS",												#	Diagnostic Policy Service
	"WdiServiceHost",									#	Diagnostic Service Host
	"WdiSystemHost",									#	Diagnostic System Host
	"TrkWks",											#	Distributed Link Tracking Client					https://docs.microsoft.com/en-us/windows/win32/fileio/distributed-link-tracking-and-object-identifiers?redirectedfrom=MSDN
	"MSDTC",											#	Distributed Transaction Coordinator					https://en.wikipedia.org/wiki/Microsoft_Distributed_Transaction_Coordinator
	"MapsBroker",										#	Downloaded Maps Manager
	"EFS",												#	Encrypting File System
	"EntAppSvc",										#	Enterprise App Management Service
	"fdPHost",											#	Function Discovery Provider Host
    "FDResPub",											#	Function Discovery Resource Publication
    "lfsvc",											#	Geolocation Service
	"HvHost",											#	HV Host Service
	"vmickvpexchange",									#	Hyper-V Data Exchange Service
	"vmicguestinterface",								#	Hyper-V Guest Service Interface
	"vmicshutdown",										#	Hyper-V Guest Shutdown Service
	"vmicheartbeat",									#	Hyper-V Heartbeat Service
	"vmicvmsession",									#	Hyper-V PowerShell Direct Service
	"vmicrdv",											#	Hyper-V Remote Desktop Virtualization Service
	"vmictimesync",										#	Hyper-V Time Synchronization Service
	"vmicvss",											#	Hyper-V Volume Shadow Copy Requestor
	"SharedAccess",										#	Internet Connection Sharing							https://en.wikipedia.org/wiki/Internet_Connection_Sharing
	"iphlpsvc",											#	IP Helper											https://docs.microsoft.com/en-us/windows/win32/iphlp/about-ip-helper
	"wlidsvc",											#	Microsoft Account Sign-in Assistant					Disable only if you aren't using Microsoft Account sign ins
	"AppVclient",										#	Microsoft App-V Client								Disable if you don't use Microsoft App-V for virtual applications
    "MSiSCSI",											#	Microsoft iSCSI Initiator Service
    "swprv",											#	Microsoft Software Shadow Copy Provider
	"uhssvc",											#	Microsoft Update Health Service
#	DISABLED BY DEFAULT "NcbService",					#	Network Connection Broker							Do not Disable this Service.  Connected Devices Platform Service is dependency.		Listed here for informational purposes.
    "CscService",										#	Offline Files
	"defragsvc",										#	Optimize drives (Defrag Service)
    "PhoneSvc",											#	Phone Service
	"WPDBusEnum",										#	Portable Device Enumerator Service					Used for enforcing Group Policy management of removable mass-storage devices
	"wercplsupport",									#	Problem Reports Control Panel Support
	"PcaSvc",											#	Program Compatibility Assistant Service
	"SensorDataService",								#	Sensor Data Service
	"SensrSvc",											#	Sensor Monitoring Service
	"SSDPSRV",											#	SSDP Discovery
    "SysMain",											#	SysMain on Windows 10; Superfetch on Windows Server
	"Themes",											#	Themes												Disable if you don't wish to use Themes	
	"UsoSvc",											#	Update Orchestrator Service							Part of the Windows Update Process
	"upnphost",											#	UPnP Device Host
	"icssvc",											#	Windows Mobile Hotspot Service
    "Wsearch",											#	Windows Search
    "wuauserv",											#	Windows Update										Part of the Windows Update Process
    "XblAuthManager",									#	XblAuthManager
    "XblGameSave",										#	XblGaveSave
    "XboxNetApiSvc"										#	XboxNetApiSvc
)

$ServicesCounter = 0

ForEach($Service in $Services) {
    If ($Service.Contains('*')) {
        $NewService = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\$Service").PSChildName
        $ServiceArray = $NewService.split(" ")
        $NewService = $ServiceArray[0]
        $ServiceStart = Get-ItemPropertyValue -Path "HKLM:\System\CurrentControlSet\Services\$NewService" -Name "Start"
        Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Services" -Name $NewService -Type "DWord" -Value $ServiceStart -ErrorAction SilentlyContinue -Verbose
    }
    Else {
        $ServiceStart = Get-ItemPropertyValue -Path "HKLM:\System\CurrentControlSet\Services\$Service" -Name "Start"
        Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Services" -Name $Service -Type "DWord" -Value $ServiceStart -ErrorAction SilentlyContinue -Verbose
    }
	Stop-Service $Service -Force -ErrorAction SilentlyContinue -Verbose
    $VerifyServiceStopped = Get-Service $Service  -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq "Stopped"} | select -last 1
    If ($VerifyServiceStopped) {
        "$(Get-TimeStamp)            $Service Verified Stopped."
        Set-Service $Service -StartupType Disabled -ErrorAction SilentlyContinue -Verbose
        $VerifyServiceDisabled = Get-Service $Service | Where-Object {$_.StartType -eq "Disabled"} | select -last 1
        If ($VerifyServiceDisabled) {
            "$(Get-TimeStamp)            $Service Verified Disabled."
			"-----------------------------------------------------------------------"
		}
        Else {
            "$(Get-TimeStamp)            $Service Verified Not Disabled!  Trying Alternate Method"
            Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\$Service -Name Start -Type DWord -Value 4 -ErrorAction SilentlyContinue -Verbose
            $VerifyServiceDisabled1 = Get-Service $Service | Where-Object {$_.StartType -eq "Disabled"} | select -last 1
            If ($VerifyServiceDisabled1) {
            "$(Get-TimeStamp)            $Service Verified Disabled using Alternate Method."}
			"-----------------------------------------------------------------------"
        }
	}
	$ServicesCounter++
	Write-Progress -Activity "Optimizing Windows Services" -Id 120 -ParentId 10 -PercentComplete (($ServicesCounter / $Services.count) * 100)
}

If (($OSMajorVersion -like "*Windows 10*") -or ($OSMajorVersion -like "*Server 2019*")){

<#
	The below Services pertain to Windows 10 and Server 2019
#>

	$W10Services = @(
		"AarSvc*",											#	Agent Activation Runtime							Service Name and Display Name change per user
		"AssignedAccessManagerSvc",							#	AssignedAccessManager
		"BDESVC",											#	BitLocker Drive Encryption Service
		"wbengine",											#	Block Level Backup Engine Service
		"BTAGService",										#	Bluetooth Audio Gateway Service
		"BluetoothUserService*",							#	Bluetooth User Support Service
		"PeerDistSvc",										#	BranchCache
	#	(DISABLED BY DEFAULT) "camsvc",						#	Capability Access Manager Service					Disabling this service will cause Sysprep issues			Listed here for informational purposes
		"CaptureService*",									#	CaptureService										Service Name and Display Name change per user
		"autotimesvc",										#	Cellular Time
		"CDPUserSvc*",										#	Connected Devices Platform User Service				Service Name and Display Name change per user
		"ConsentUxUserSvc*",								#	ConsentUX											Service Name and Display Name change per user
		"DusmSvc",											#	Data Usage
		"DoSvc",											#	Delivery Optimization
		"DevicePickerUserSvc*",								#	Device Picker										Service Name and Display Name change per user
		"DevicesFlowUserSvc*",								#	Devices Flow										Service Name and Display Name change per user
		"Fax",												#	Fax
		"GraphicsPerfSvc",									#	GraphicsPerfSvc										Used for Graphics Monitoring
		"LxpSvc",											#	Language Experience Service							Do not disable if you plan to use additional Language Packs
		"MessagingService*",								#	MessagingService									Service Name and Display Name change per user
		"WpcMonSvc",										#	Parental Controls
		"RetailDemo",										#	Retail Demo Service
		"VacSvc",											#	Volumetric Audio Compositor Service
		"WFDSConMgrSvc",									#	Wi-Fi Direct Services Connection Manager Service	Remove entry if Wi-Fi connected physical machine			Not necessary in VDI scenarios
		"SDRSVC",											#	Windows Backup										Remove entry if physical machines containing backups		Not necessary in VDI scenarios
		"WbioSrvc",											#	Windows Biometric Service
		"wcncsvc",											#	Windows Connect Now - Config Registrar
		"WMPNetworkSvc",									#	Windows Media Player Network Sharing Service
		"PushToInstall",									#	Windows PushToInstall Service
		"WaasMedicSvc",										#	Windows Update Medic Service						Part of the Windows Update Process
		"WlanSvc",											#	WLAN AutoConfig
		"workfolderssvc",									#	Work Folders
		"WwanSvc",											#	WWAN AutoConfig
		"XboxGipSvc"										#	Xbox Accessory Management Service
	)
		
	$ServicesCounter = 0

	ForEach($Service in $W10Services) {
		If ($Service.Contains('*')) {
			$NewService = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\$Service").PSChildName
			$ServiceArray = $NewService.split(" ")
			$NewService = $ServiceArray[0]
			$ServiceStart = Get-ItemPropertyValue -Path "HKLM:\System\CurrentControlSet\Services\$NewService" -Name "Start" -ErrorAction SilentlyContinue
			Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Services" -Name $NewService -Type "DWord" -Value $ServiceStart -ErrorAction SilentlyContinue -Verbose
		}
		Else {
			$ServiceStart = Get-ItemPropertyValue -Path "HKLM:\System\CurrentControlSet\Services\$Service" -Name "Start" -ErrorAction SilentlyContinue
			Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Services" -Name $Service -Type "DWord" -Value $ServiceStart -ErrorAction SilentlyContinue -Verbose
		}
		Stop-Service $Service -Force  -ErrorAction SilentlyContinue -Verbose
		$VerifyServiceStopped = Get-Service $Service  -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq "Stopped"} | select -last 1
		If ($VerifyServiceStopped) {
			"$(Get-TimeStamp)            $Service Verified Stopped."
			Set-Service $Service -StartupType Disabled -ErrorAction SilentlyContinue -Verbose
			$VerifyServiceDisabled = Get-Service $Service | Where-Object {$_.StartType -eq "Disabled"} | select -last 1
			If ($VerifyServiceDisabled) {
				"$(Get-TimeStamp)            $Service Verified Disabled."
				"-----------------------------------------------------------------------"
			}
			Else {
				"$(Get-TimeStamp)            $Service Verified Not Disabled!  Trying Alternate Method"
				Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\$Service -Name Start -Type DWord -Value 4 -ErrorAction SilentlyContinue -Verbose
				$VerifyServiceDisabled1 = Get-Service $Service | Where-Object {$_.StartType -eq "Disabled"} | select -last 1
				If ($VerifyServiceDisabled1) {
				"$(Get-TimeStamp)            $Service Verified Disabled using Alternate Method."}
				"-----------------------------------------------------------------------"
			}
		}
		$ServicesCounter++
		Write-Progress -Activity "Optimizing Windows Services" -Id 120 -ParentId 10 -PercentComplete (($ServicesCounter / $W10Services.count) * 100)
	}

}

Write-Progress -Activity "Optimizing Windows Services" -Id 120 -ParentId 10 -PercentComplete 100 -Completed

$OSOpsCounter++
Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete (($OSOpsCounter / $OSOps) * 100)

$OPsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

<#
	If you wish to use a multi-selectable GUI to disable services, use the below.
	Please note the below doesn't stop the services, as it does with the array above.
	Only displays Services that are not Disabled

	Get-Service | Where-Object {$_.Status -ne "Disabled"} | Out-GridView -PassThru | Set-Service -StartupType Disabled
#>

"$(Get-TimeStamp)		End Of Optimizing"
"				$OSMajorVersion $OSMinorVersion"
"				Services."
"-----------------------------------------------------------------------"

#endregion Service Optimizations

#region Scheduled Task Optimizations
<#
	Disables Scheduled Tasks
	Array Methodology
#>

Write-Progress -Activity "Optimizing Windows Scheduled Tasks" -Id 130 -ParentId 10 -PercentComplete 0

"$(Get-TimeStamp)            Optimizing $OSMajorVersion $OSMinorVersion Scheduled Tasks."

<#
	The below Scheduled Tasks pertain to Windows 10 and Server 2016/2019
#>

$ScheduledTasksCounter = 0

$ScheduledTaskLocations = @(
	"\Microsoft\Windows\Application Experience\",
	"\Microsoft\Windows\Application Experience\",
	"\Microsoft\Windows\Autochk\",
	"\Microsoft\Windows\Bluetooth\",
	"\Microsoft\Windows\Data Integrity Scan\",
	"\Microsoft\Windows\Data Integrity Scan\",
	"\Microsoft\Windows\Data Integrity Scan\",
	"\Microsoft\Windows\Diagnosis\",
	"\Microsoft\Windows\DiskCleanup\",
	"\Microsoft\Windows\DiskDiagnostic\",
	"\Microsoft\Windows\DiskDiagnostic\",
	"\Microsoft\Windows\DiskFootprint\",
	"\Microsoft\Windows\DiskFootprint\",
	"\Microsoft\Windows\FileHistory\",
	"\Microsoft\Windows\Location\",
	"\Microsoft\Windows\Maintenance\",
	"\Microsoft\Windows\Maps\",
	"\Microsoft\Windows\Maps\",
	"\Microsoft\Windows\MemoryDiagnostic\",
	"\Microsoft\Windows\MemoryDiagnostic\",
	"\Microsoft\Windows\Mobile Broadband Accounts\",
	"\Microsoft\Windows\NetTrace\",
	"\Microsoft\Windows\Offline Files\",
	"\Microsoft\Windows\Offline Files\",
	"\Microsoft\Windows\PI\",
	"\Microsoft\Windows\Power Efficiency Diagnostics\",
	"\Microsoft\Windows\Ras\",
	"\Microsoft\Windows\RecoveryEnvironment\",
	"\Microsoft\Windows\Registry\",
	"\Microsoft\Windows\Servicing\",
	"\Microsoft\Windows\Shell\",
	"\Microsoft\Windows\SpacePort\",
	"\Microsoft\Windows\SpacePort\",
	"\Microsoft\Windows\Speech\",
	"\Microsoft\Windows\Windows Error Reporting\",
	"\Microsoft\Windows\Windows Filtering Platform\",
	"\Microsoft\Windows\WindowsUpdate\",
	"\Microsoft\XblGameSave\"
)

$ScheduledTaskNames = @(
	"Microsoft Compatibility Appraiser",
	"ProgramDataUpdater",
	"Proxy",
	"UninstallDeviceTask",
	"Data Integrity Check and Scan",
	"Data Integrity Scan",
	"Data Integrity Scan for Crash Recovery",
	"Scheduled",
	"SilentCleanup",
	"Microsoft-Windows-DiskDiagnosticDataCollector",
	"Microsoft-Windows-DiskDiagnosticResolver",
	"Diagnostics",
	"StorageSense",
	"File History (maintenance mode)",
	"Notifications",
	"WinSAT",
	"MapsToastTask",
	"MapsUpdateTask",
	"ProcessMemoryDiagnosticEvents",
	"RunFullMemoryDiagnostic",
	"MNO Metadata Parser",
	"GatherNetworkInfo",
	"Background Synchronization",
	"Logon Synchronization",
	"Sqm-Tasks",
	"AnalyzeSystem",
	"MobilityManager",
	"VerifyWinRE",
	"RegIdleBackup",
	"StartComponentCleanup",
	"IndexerAutomaticMaintenance",
	"SpaceAgentTask",
	"SpaceManagerTask",
	"SpeechModelDownloadTask",
	"QueueReporting",
	"BfeOnServiceStartTypeChange",
	"Scheduled Start",
	"XblGameSaveTask"
)

For ($ScheduledTasksRevertCounter = 0; $ScheduledTasksRevertCounter -le 37; $ScheduledTasksRevertCounter++) {
	$ScheduledTask = $ScheduledTaskLocations[$ScheduledTasksRevertCounter] + $ScheduledTaskNames[$ScheduledTasksRevertCounter]
	$ScheduledTaskState = (Get-ScheduledTask -TaskPath $ScheduledTaskLocations[$ScheduledTasksRevertCounter] -TaskName $ScheduledTaskNames[$ScheduledTasksCounter]).State
	Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Scheduled Tasks" -Name $ScheduledTask -Type "String" -Value $ScheduledTaskState -ErrorAction SilentlyContinue -Verbose
	Disable-ScheduledTask -TaskName $ScheduledTask -ErrorAction SilentlyContinue -Verbose
    "$(Get-TimeStamp)            $ScheduledTask Scheduled Task Disabled."
	"-----------------------------------------------------------------------"
	$ScheduledTasksCounter++
	Write-Progress -Activity "Optimizing Windows Scheduled Tasks" -Id 130 -ParentId 10 -PercentComplete (($ScheduledTasksCounter / $ScheduledTaskNames.count) * 100)
}

If (($OSMajorVersion -like "*Windows 10*") -or ($OSMajorVersion -like "*Server 2019*")) {

<#
	The below Scheduled Tasks pertain to Windows 10 and Server 2019
#>

	$ScheduledTasksCounter = 0

	$ScheduledTaskLocations = @(
		"\Microsoft\Windows\Application Experience\",
		"\Microsoft\Windows\BrokerInfrastructure\",
		"\Microsoft\Windows\Chkdsk\",
		"\Microsoft\Windows\CloudExperienceHost\",
		"\Microsoft\Windows\Customer Experience Improvement Program\",
		"\Microsoft\Windows\Customer Experience Improvement Program\",
		"\Microsoft\Windows\Defrag\",
		"\Microsoft\Windows\Diagnosis\",
		"\Microsoft\Windows\Flighting\FeatureConfig\",
		"\Microsoft\Windows\Flighting\OneSettings\",
		"\Microsoft\Windows\HelloFace\",
		"\Microsoft\Windows\InstallService\",
		"\Microsoft\Windows\InstallService\",
		"\Microsoft\Windows\InstallService\",
		"\Microsoft\Windows\International\",
		"\Microsoft\Windows\LanguageComponentsInstaller\",
		"\Microsoft\Windows\Location\",
		"\Microsoft\Windows\Management\Provisioning\",
		"\Microsoft\Windows\NlaSvc\",
		"\Microsoft\Windows\PushToInstall\",
		"\Microsoft\Windows\PushToInstall\",
		"\Microsoft\Windows\Shell\",
		"\Microsoft\Windows\Shell\",
		"\Microsoft\Windows\StateRepository\",
		"\Microsoft\Windows\Subscription\",
		"\Microsoft\Windows\Subscription\",
		"\Microsoft\Windows\Sysmain\",
		"\Microsoft\Windows\Sysmain\",
		"\Microsoft\Windows\SystemRestore\",
		"\Microsoft\Windows\USB\",
		"\Microsoft\Windows\WCM\",
		"\Microsoft\Windows\WDI\",
		"\Microsoft\Windows\Windows Defender\",
		"\Microsoft\Windows\Windows Defender\",
		"\Microsoft\Windows\Windows Defender\",
		"\Microsoft\Windows\Windows Defender\",
		"\Microsoft\Windows\Windows Media Sharing\",
		"\Microsoft\Windows\Work Folders\",
		"\Microsoft\Windows\Work Folders\",
		"\Microsoft\Windows\WOF\",
		"\Microsoft\Windows\WOF\",
		"\Microsoft\Windows\WwanSvc\"
	)

	$ScheduledTaskNames = @(
		"StartupAppTask",
		"BgTaskRegistrationMaintenanceTask",
		"ProactiveScan",
		"CreateObjectTask",
		"Consolidator",
		"UsbCeip",
		"ScheduledDefrag",
		"RecommendedTroubleshootingScanner",
		"ReconcileFeatures",
		"RefreshCache",
		"FODCleanupTask",
		"ScanForUpdates",
		"ScanForUpdatesAsUser",
		"SmartRetry",
		"Synchronize Language Settings",
		"ReconcileLanguageResources",
		"WindowsActionDialog",
		"Cellular",
		"WiFiTask",
		"LoginCheck",
		"Registration",
		"FamilySafetyMonitor",
		"FamilySafetyRefreshTask",
		"MaintenanceTasks",
		"EnableLicenseAcquisition",
		"LicenseAcquisition",
		"ResPriStaticDbSync",
		"WsSwapAssessmentTask",
		"SR",
		"Usb-Notifications",
		"WiFiTask",
		"ResolutionHost",
		"Windows Defender Cache Maintenance",
		"Windows Defender Cleanup",
		"Windows Defender Scheduled Scan",
		"Windows Defender Verification",
		"UpdateLibrary",
		"Work Folders Logon Synchronization",
		"Work Folders Maintenance Work",
		"WIM-Hash-Management",
		"WIM-Hash-Validation",
		"NotificationTask"
	)
	
	For ($ScheduledTasksRevertCounter = 0; $ScheduledTasksRevertCounter -le 41; $ScheduledTasksRevertCounter++) {
		$ScheduledTask = $ScheduledTaskLocations[$ScheduledTasksRevertCounter] + $ScheduledTaskNames[$ScheduledTasksRevertCounter]
		$ScheduledTaskState = (Get-ScheduledTask -TaskPath $ScheduledTaskLocations[$ScheduledTasksRevertCounter] -TaskName $ScheduledTaskNames[$ScheduledTasksRevertCounter] -ErrorAction SilentlyContinue).State
		Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Scheduled Tasks" -Name $ScheduledTask -Type "String" -Value $ScheduledTaskState -ErrorAction SilentlyContinue -Verbose
		Disable-ScheduledTask -TaskName $ScheduledTask -ErrorAction SilentlyContinue -Verbose
		"$(Get-TimeStamp)            $ScheduledTask Scheduled Task Disabled."
		"-----------------------------------------------------------------------"
		$ScheduledTasksCounter++
		Write-Progress -Activity "Optimizing Windows Scheduled Tasks" -Id 130 -ParentId 10 -PercentComplete (($ScheduledTasksCounter / $ScheduledTaskNames.count) * 100)
	}
}

If ($OSMajorVersion -like "*Windows Server*"){

<#
	The below Scheduled Tasks pertain to Server 2016/2019
#>

	$ScheduledTasksCounter = 0

	$ScheduledTaskLocations = @(
		"\Microsoft\Windows\Customer Experience Improvement Program\",
		"\Microsoft\Windows\SettingSync\",
		"\Microsoft\Windows\SettingSync\",
		"\Microsoft\Windows\Setup\",
		"\Microsoft\Windows\Software Inventory Logging\",
		"\Microsoft\Windows\UpdateOrchestrator\",
		"\Microsoft\Windows\WindowsUpdate\",
		"\Microsoft\XblGameSave\"
	)
	
	$ScheduledTaskNames = @(
		"KernelCeipTask",
		"BackgroundUploadTask",
		"BackUpTask",
		"SetupCleanupTask",
		"Configuration",
		"USO_UxBroker_ReadyToReboot",
		"Automatic App Update",
		"XblGameSaveTaskLogon"
	)

	For ($ScheduledTasksRevertCounter = 0; $ScheduledTasksRevertCounter -le 7; $ScheduledTasksRevertCounter++) {
		$ScheduledTask = $ScheduledTaskLocations[$ScheduledTasksRevertCounter] + $ScheduledTaskNames[$ScheduledTasksRevertCounter]
		$ScheduledTaskState = (Get-ScheduledTask -TaskName $ScheduledTaskNames[$ScheduledTasksRevertCounter] -ErrorAction SilentlyContinue).State
		Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Scheduled Tasks" -Name $ScheduledTask -Type "String" -Value $ScheduledTaskState -ErrorAction SilentlyContinue -Verbose
		Disable-ScheduledTask -TaskName $ScheduledTask -ErrorAction SilentlyContinue -Verbose
		"$(Get-TimeStamp)            $ScheduledTask Scheduled Task Disabled."
		"-----------------------------------------------------------------------"
		$ScheduledTasksCounter++
		Write-Progress -Activity "Optimizing Windows Scheduled Tasks" -Id 130 -ParentId 10 -PercentComplete (($ScheduledTasksCounter / $ScheduledTaskNames.count) * 100)
	}

}

Write-Progress -Activity "Optimizing Windows Scheduled Tasks" -Id 130 -ParentId 10 -PercentComplete 100 -Completed

$OSOpsCounter++
Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete (($OSOpsCounter / $OSOps) * 100)

$OPsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

<#
	If you wish to use a multi-selectable GUI to disable scheduled tasks, use the below.
	This will only show Scheduled Tasks that are in the Ready State

	Get-ScheduledTask | Where-Object {$_.State -eq "Ready"} | Out-GridView -PassThru | Disable-ScheduledTask

	The below Scheduled Tasks can't be disabled through the Task Scheduler applet.  You must fully, and manually, delete the registry key they are based upon.
	This action, as opposed to disabling them above, is irreversible.
	Please vet these Scheduled Tasks carefully.

	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\BitLocker\BitLocker Encrypt All Drives"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\BitLocker\BitLocker MDM policy Refresh"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\Chkdsk\SyspartRepair"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\SettingSync\BackgroundUploadTask"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\UpdateOrchestrator\Schedule Scan Static Task"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\UpdateOrchestrator\UpdateModelTask"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\WaaSMedic\PerformRemediation"
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Task Cache\Tree\Microsoft\Windows\WindowsUpdate\sihpostreboot"
#>

"$(Get-TimeStamp)		End Of Optimizing"
"				$OSMajorVersion $OSMinorVersion"
"				Scheduled Tasks."
"-----------------------------------------------------------------------"

#endregion Scheduled Task Optimizations

#region Active Setup Optimizations
<#
	Removes Active Setup entries - See https://www.nutanix.com/blog/windows-os-optimization-essentials-part-1-active-setup for more information
#>

Write-Progress -Activity "Optimizing Windows Active Setup" -Id 140 -ParentId 10 -PercentComplete 0

"$(Get-TimeStamp)            Optimizing $OSMajorVersion $OSMinorVersion Active Setup."

$ActiveSetupNames = @(
	"Themes Setup",
	"Microsoft Windows Media Player",
	"Windows Desktop Update",
	"Web Platform Customizations",
	"DOTNETFRAMEWORKS",
	"Microsoft Windows Media Player"
)

$ActiveSetupKeys = @(
	"{2C7339CF-2B09-4501-B3F3-F3508C9228ED}",						#Themes Setup
	"{6BF52A52-394A-11d3-B153-00C04F79FAA6}",						#Microsoft Windows Media Player
	"{89820200-ECBD-11cf-8B85-00AA005B4340}",						#Windows Desktop Update
	"{89820200-ECBD-11cf-8B85-00AA005B4383}",						#Web Platform Customizations
	"{89B4C1CD-B018-4511-B0A1-5476DBF70820}",						#DOTNETFRAMEWORKS
	">{22d6f312-b0f6-11d0-94ab-0080c74c7e95}"						#Microsoft Windows Media Player
)

$ActiveSetupCounter = 0
$ActiveSetupNameCounter = 0

ForEach ($ActiveSetupKey in $ActiveSetupKeys){
    $64bitActiveSetup = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$ActiveSetupKey"
    If ($64bitActiveSetup -eq $True) {
        $StubPathExists = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$ActiveSetupKey").PSObject.Properties.Name -contains "Stubpath"
        If ($StubPathExists -eq $True) {
            New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Active Setup\64bit\$ActiveSetupKey" -ErrorAction SilentlyContinue -Verbose
            $StubPath = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "Stubpath" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Active Setup\64bit\$ActiveSetupKey" -Name $ActiveSetupNames[$ActiveSetupNameCounter] -Type "String" -Value $StubPath -ErrorAction SilentlyContinue -Verbose
            Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "StubPath" -ErrorAction SilentlyContinue -Verbose
        }
    }
    $32bitActiveSetup = Test-Path -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey"
    If ($32bitActiveSetup -eq $True) {
        $StubPathExists = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey").PSObject.Properties.Name -contains "Stubpath"
        If ($StubPathExists -eq $True) {
            New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Active Setup\32bit\$ActiveSetupKey" -ErrorAction SilentlyContinue -Verbose
            $StubPath = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "Stubpath" -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Active Setup\32bit\$ActiveSetupKey" -Name $ActiveSetupNames[$ActiveSetupNameCounter] -Type "String" -Value $StubPath -ErrorAction SilentlyContinue -Verbose
            Remove-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "StubPath" -ErrorAction SilentlyContinue -Verbose
        }
    }
	"$(Get-TimeStamp)            $ActiveSetupNames[ActiveSetupNameCounter] Active Setup Optimized."
	"-----------------------------------------------------------------------"
    $ActiveSetupNameCounter++
	$ActiveSetupCounter++
	Write-Progress -Activity "Optimizing Windows Active Setup" -Id 140 -ParentId 10 -PercentComplete (($ActiveSetupCounter / $ActiveSetupKeys.count) * 100)
}

If ($OSMajorVersion -like "*Windows Server*"){

<#
	The below Active Setup Keys pertain to Server 2016/2019
#>

	$ActiveSetupNames = @(
		"Outlook Express Setup",
		"Enhanced Security Configuration",
		"Enhanced Security Configuration"
	)
	
	$ActiveSetupKeys = @(
		"{44BBA840-CC51-11CF-AAFA-00AA00B6015C}",					#Outlook Express Setup
		"{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}",					#Enhanced Security Configuration
		"{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"					#Enhanced Security Configuration
	)

	$ActiveSetupCounter = 0
	$ActiveSetupNameCounter = 0

	ForEach ($ActiveSetupKey in $ActiveSetupKeys){
		$64bitActiveSetup = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$ActiveSetupKey"
		If ($64bitActiveSetup -eq $True) {
			$StubPathExists = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$ActiveSetupKey").PSObject.Properties.Name -contains "Stubpath"
			If ($StubPathExists -eq $True) {
				New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Active Setup\64bit\$ActiveSetupKey" -ErrorAction SilentlyContinue -Verbose
				$StubPath = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "Stubpath" -ErrorAction SilentlyContinue
				Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Active Setup\64bit\$ActiveSetupKey" -Name $ActiveSetupNames[$ActiveSetupNameCounter] -Type "String" -Value $StubPath -ErrorAction SilentlyContinue -Verbose
				Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "StubPath" -ErrorAction SilentlyContinue -Verbose
			}
		}
		$32bitActiveSetup = Test-Path -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey"
		If ($32bitActiveSetup -eq $True) {
			$StubPathExists = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey").PSObject.Properties.Name -contains "Stubpath"
			If ($StubPathExists -eq $True) {
				New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Nutanix\WOSTT\Active Setup\32bit\$ActiveSetupKey" -ErrorAction SilentlyContinue -Verbose
				$StubPath = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "Stubpath" -ErrorAction SilentlyContinue
				Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Active Setup\32bit\$ActiveSetupKey" -Name $ActiveSetupNames[$ActiveSetupNameCounter] -Type "String" -Value $StubPath -ErrorAction SilentlyContinue -Verbose
				Remove-ItemProperty -Path "HKLM:\Software\Wow6432Node\Microsoft\Active Setup\Installed Components\$ActiveSetupKey" -Name "StubPath" -ErrorAction SilentlyContinue -Verbose
			}
		}
		"$(Get-TimeStamp)            $ActiveSetupNames[$ActiveSetupNameCounter] Active Setup Optimized."
		"-----------------------------------------------------------------------"
		$ActiveSetupNameCounter++
		$ActiveSetupCounter++
		Write-Progress -Activity "Optimizing Windows Active Setup" -Id 140 -ParentId 10 -PercentComplete (($ActiveSetupCounter / $ActiveSetupKeys.count) * 100)
	}
}

Write-Progress -Activity "Optimizing Windows Active Setup" -Id 140 -ParentId 10 -PercentComplete 100 -Completed

$OSOpsCounter++
Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete (($OSOpsCounter / $OSOps) * 100)

$OPsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

"$(Get-TimeStamp)		End Of Optimizing"
"				$OSMajorVersion $OSMinorVersion"
"				Active Setup."
"-----------------------------------------------------------------------"

#endregion Active Setup Optimizations

#region Autologger Optimizations
<#
	Disables Autologgers
	Autologgers are started at boot, so any disabled Autologgers will require a reboot
	What is an autologger? - https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/what-is-an-autologger-
	What is a trace session? - https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/trace-session
	What is trace during boot? - https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/tracing-during-boot
#>

Write-Progress -Activity "Optimizing Windows Autologgers" -Id 150 -ParentId 10 -PercentComplete 0

"$(Get-TimeStamp)            Optimizing $OSMajorVersion $OSMinorVersion Autologgers."

$AutoLoggerCounter = 0

$Autologgers = @(
    "AppModel",														#	https://docs.microsoft.com/en-us/windows/win32/api/appmodel/
	"Cellcore",														#	https://docs.microsoft.com/en-us/windows-hardware/drivers/network/cellular-architecture-and-driver-model
    "CloudExperienceHostOOBE",										#	https://docs.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-how-it-works-technology#cloud-experience-host
    "DiagLog",														#	https://docs.microsoft.com/en-us/windows-server/security/windows-services/security-guidelines-for-disabling-system-services-in-windows-server
	"Diagtrack-Listener",											#	Telemetry based Trace Session
	# (DO NOT ENABLE - To be researched further) "RadioMgr",		#	https://docs.microsoft.com/en-us/windows-hardware/drivers/nfc/what-s-new-in-nfc-device-drivers
	"ReadyBoot",													#	https://docs.microsoft.com/en-us/previous-versions/windows/desktop/xperf/readyboot-analysis
    "WDIContextLog",												#	https://docs.microsoft.com/en-us/windows-hardware/drivers/network/wifi-universal-driver-model
    "WiFiDriverIHVSession",											#	https://docs.microsoft.com/en-us/windows-hardware/drivers/network/user-initiated-feedback-normal-mode
	"WiFiSession"
	# (DO NOT ENABLE - To be researched further) "WinPhoneCritical"
)

ForEach($Autologger in $Autologgers) {
	$AutologgerStart = (Get-AutologgerConfig -Name $Autologger).Start
	Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Autologger" -Name $Autologger -Type "DWORD" -Value $AutologgerStart -ErrorAction SilentlyContinue -Verbose
    Set-AutologgerConfig -Name $Autologger -Start 0 -ErrorAction SilentlyContinue -Verbose
	"$(Get-TimeStamp)            $Autologger Optimized."
	"-----------------------------------------------------------------------"
	$AutoLoggerCounter++
	Write-Progress -Activity "Optimizing Windows Autologgers" -Id 150 -ParentId 10 -PercentComplete (($AutoLoggerCounter / $Autologgers.count) * 100)
}

Write-Progress -Activity "Optimizing Windows Autologgers" -Id 150 -ParentId 10 -PercentComplete 100 -Completed

$OSOpsCounter++
Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete (($OSOpsCounter / $OSOps) * 100)

$OPsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

"$(Get-TimeStamp)		End Of Optimizing"
"				$OSMajorVersion $OSMinorVersion"
"				Autologgers."
"-----------------------------------------------------------------------"

#endregion Autologger Optimizations

#region Optional Feature Optimizations
<#
	Disabling Windows Optional Features
#>

Write-Progress -Activity "Optimizing Windows Optional Features" -Id 160 -ParentId 10 -PercentComplete 0

"$(Get-TimeStamp)            Optimizing $OSMajorVersion $OSMinorVersion Optional Features."

$OptionalFeatures = @(
	"Printing-XPSServices-Features",						#	Disables the Print to XPS Printer								Provides support for Microsoft's ".XPS" file format, which is an alternative to Adobe's ."PDF" format.
	"WindowsMediaPlayer",									#	Disables Windows Media Player									The default media player that's bundled with Windows. If you do not use it to play music or videos, you can remove it.
	"WorkFolders-Client",									#	Disables Work Folders Client									This tool allows you to synchronize folders from a corporate network to your computer.
	"Internet-Explorer-Optional-amd64"						#	Disables Internet Explorer 11									Internet Explorer 11 Browser.  Do not disable if alternate primary browser application is not installed.
	"MediaPlayback",										#	Disables MediaPlayback											MediaPlayback controls media features such as Windows Media Player
	"MSRDC-Infrastructure"									#	Disables MS Remote Differential Compression (RDC) API Support	Supports RDC in third-party applications
)

$OptionalFeatureCounter = 0

Write-Progress -Activity "Optimizing Windows Optional Features" -Id 161 -ParentId 10 -PercentComplete 0

ForEach($OptionalFeature in $OptionalFeatures) {
	$OptionalFeatureState = (Get-WindowsOptionalFeature -Online -FeatureName $OptionalFeature -ErrorAction SilentlyContinue).state
	If ($OptionalFeatureState -eq "DisablePending") {
		$OptionalFeatureState = "Disabled"
	}
	If ($OptionalFeatureState -eq "EnablePending") {
		$OptionalFeatureState = "Enabled"
	}
	Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Optional Features" -Name $OptionalFeature -Type "String" -Value $OptionalFeatureState -ErrorAction SilentlyContinue -Verbose
	Disable-WindowsOptionalFeature -Online -FeatureName $OptionalFeature -Remove -NoRestart -ErrorAction SilentlyContinue -Verbose
	"$(Get-TimeStamp)            $OptionalFeature Optimized."
	"-----------------------------------------------------------------------"
	$OptionalFeatureCounter++
	$OptionalFeatureRestartRequired = (Get-WindowsOptionalFeature -Online -FeatureName $OptionalFeature -ErrorAction SilentlyContinue).restartrequired
	If ($OptionalFeatureRestartRequired -eq "Required") {
		$RebootRequiredStatus = "True"
	}
	Write-Progress -Activity "Optimizing Windows Optional Features" -Id 161 -ParentId 10 -PercentComplete (($OptionalFeatureCounter / $OptionalFeatures.count) * 100)
}

Write-Progress -Activity "Optimizing Windows Optional Features" -Id 161 -ParentId 10 -PercentComplete 100 -Completed

Write-Progress -Activity "Optimizing Windows Server Optional Features" -Id 162 -ParentId 10 -PercentComplete 0

$OptionalFeatureCounter = 0

If ($OSMajorVersion -like "*Windows Server*"){
	$S16OptionalFeatures = @(
		"Microsoft-Windows-Printing-XPSServices-Package",		#	Disables the Print to XPS Printer			Provides support for Microsoft's ".XPS" file format, which is an alternative to Adobe's."PDF" format.
		"Microsoft-Hyper-V-Common-Drivers-Package",				#	Disables Hyper-V Common Drivers
		"Microsoft-Hyper-V-Guest-Integration-Drivers-Package"	#	Disables Hyper-V Guest Integration Services
	)
	ForEach($OptionalFeature in $S16OptionalFeatures) {
		$OptionalFeatureState = (Get-WindowsOptionalFeature -Online -FeatureName $OptionalFeature -ErrorAction SilentlyContinue).state
		If ($OptionalFeatureState -eq "DisablePending") {
			$OptionalFeatureState = "Disabled"
		}
		If ($OptionalFeatureState -eq "EnablePending") {
			$OptionalFeatureState = "Enabled"
		}
		Set-ItemProperty -Path "HKLM:\Software\Nutanix\WOSTT\Optional Features" -Name $OptionalFeature -Type "String" -Value $OptionalFeatureState -ErrorAction SilentlyContinue -Verbose
		Disable-WindowsOptionalFeature -Online -FeatureName $OptionalFeature -Remove -NoRestart -ErrorAction SilentlyContinue -Verbose
		"$(Get-TimeStamp)            $OptionalFeature Optimized."
		"-----------------------------------------------------------------------"
		$OptionalFeatureCounter++
		$OptionalFeatureRestartRequired = (Get-WindowsOptionalFeature -Online -FeatureName $OptionalFeature -ErrorAction SilentlyContinue).restartrequired
		If ($OptionalFeatureRestartRequired -eq "Required") {
			$RebootRequiredStatus = "True"
		}
		Write-Progress -Activity "Optimizing Windows Server Optional Features" -Id 162 -ParentId 10 -PercentComplete (($OptionalFeatureCounter / $S16OptionalFeatures.count) * 100)
	}
}

Write-Progress -Activity "Optimizing Windows Server Optional Features" -Id 162 -ParentId 10 -PercentComplete 100 -Completed

Write-Progress -Activity "Optimizing Windows Optional Features" -Id 160 -ParentId 10 -PercentComplete 100 -Completed

$OSOpsCounter++
Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete (($OSOpsCounter / $OSOps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

"$(Get-TimeStamp)		End Of Optimizing"
"				$OSMajorVersion $OSMinorVersion"
"				Optional Features."
"-----------------------------------------------------------------------"

#endregion Optional Feature Optimizations

#region Generic VDI optimizations
<#
	Generic VDI optimizations
#>

$VDIOpsCounter = 0

If ($OSMajorVersion -like "*Windows 10*") {
	$VDIOps = "45"
}
Else {
	$VDIOps = "41"
}

Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete 0
"$(Get-TimeStamp)            Starting $OSMajorVersion $OSMinorVersion Generic VDI Optimizations."

#	Enable or Disable font smoothing in Windows - https://www.tenforums.com/tutorials/126775-enable-disable-font-smoothing-windows.html
$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."FontSmoothing"
If ($Value -ne "0"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "FontSmoothing" -Type "String" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."UserPreferencesMask"
If ($Value -ne "([byte[]](0x90,0x12,0x01,0x80,0x10,0x00,0x00,0x00)"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x01,0x80,0x10,0x00,0x00,0x00)) -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."CursorBlinkRate"
If ($Value -ne "-1"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "CursorBlinkRate" -Type "String" -Value -1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."ScreenSaveActive"
If ($Value -ne "0"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "ScreenSaveActive" -Type "String" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."AutoEndTasksValue"
If ($Value -ne "1"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "AutoEndTasksValue" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."WaittoKillAppTimeout"
If ($Value -ne "1000"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "WaittoKillAppTimeout" -Type "DWord" -Value 1000 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."MenuShowDelay"
If ($Value -ne "0"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "MenuShowDelay" -Type "String" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop")."MinAnimate"
If ($Value -ne "0"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "MinAnimate" -Type "String" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location1 = Test-Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer"
If ($Location1 -eq "True"){
	$Location2 = Test-Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer\Main"
	If ($Location2 -eq "True"){
        $Value =(Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer\Main")."Force Offscreen Composition"
        If ($Value -ne "1"){
            Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer\Main" -Name "Force Offscreen Composition" -Type "DWord" -Value 1 -Verbose
        }
    }
    ElseIf ($Location2 -ne "True"){
        New-Item -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer\Main" -Verbose
        Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer\Main" -Name "Force Offscreen Composition" -Type "DWord" -Value 1 -Verbose
    }
}
ElseIf ($Location1 -ne "True"){
    New-Item -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer" -Verbose
    New-Item -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer\Main" -Verbose
    Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Internet Explorer\Main" -Name "Force Offscreen Composition" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location = Test-Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Terminal Server Client"
If ($Location -eq "True"){
    $Value =(Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Terminal Server Client")."Min Send Interval"
        If ($Value -ne "1"){
            Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Terminal Server Client" -Name "Min Send Interval" -Type "DWord" -Value 1 -Verbose
        }
}
ElseIf ($Location -ne "True"){
    New-Item -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Terminal Server Client"
    Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Terminal Server Client" -Name "Min Send Interval" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location = Test-Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
If ($Location -eq "True"){
	$Value =(Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced")."ListviewAlphaSelect"
	If ($Value -ne "0"){
		Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type "DWord" -Value 0 -Verbose
	}
	$Value =(Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced")."ListviewShadow"
	If ($Value -ne "0"){
		Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type "DWord" -Value 0 -Verbose
	}
	$Value =(Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced")."TaskbarAnimations"
	If ($Value -ne "0"){
		Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type "DWord" -Value 0 -Verbose
	}
}
ElseIf ($Location -ne "True"){
    New-Item -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type "DWord" -Value 0 -Verbose
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type "Dword" -Value 0 -Verbose
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type "Dword" -Value 0 -Verbose
}

$VDIOPsCounter++
$VDIOPsCounter++
$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location = Test-Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
If ($Location -eq "True"){
    $Value =(Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects")."VisualFXSetting"
        If ($Value -ne "3"){
            Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type "DWord" -Value 3 -Verbose
        }
}
ElseIf ($Location -ne "True"){
    New-Item -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Verbose
    Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type "DWord" -Value 3 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\DWM")."EnableAeroPeek"
If ($Value -ne "0"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\DWM")."AlwaysHibernateThumbnails"
If ($Value -ne "0"){
	Set-ItemProperty -Path "Registry::HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\DWM" -Name "AlwaysHibernateThumbnails" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location1 = Test-Path "HKLM:\Software\Microsoft\Dfrg"
If ($Location1 -eq "True"){
    $Location2 = Test-Path "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction"
    If ($Location2 -eq "True"){
		$Value = (Get-ItemProperty HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction)."Enable"
		If ($Value -ne "N"){
			Set-ItemProperty -Path HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction -Name "Enable" -Value N -Verbose
		}
		$Value = (Get-ItemProperty HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction)."OptimizeComplete"
        If ($Value -ne "Yes"){
			Set-ItemProperty -Path HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction -Name "OptimizeComplete" -Value Yes -Verbose
		}
	}
    ElseIf ($Location2 -ne "True"){
        New-Item -Path "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction" -Verbose
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction" -Name "Enable" -Type "String" -Value N -Verbose
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction" -Name "OptimizeComplete" -Type "String" -Value Yes -Verbose
    }
}
ElseIf ($Location1 -ne "True"){
    New-Item -Path "HKLM:\Software\Microsoft\Dfrg" -Verbose
    New-Item -Path "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction" -Verbose
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction" -Name "Enable" -Type "String" -Value N -Verbose
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Dfrg\BootOptimizeFunction" -Name "OptimizeComplete" -Type "String" -Value Yes -Verbose
}

$VDIOPsCounter++
$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{025A5937-A6BE-4686-A844-36FE4BEC8B6D}")."PreferredPlan"
If ($Value -ne "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"){
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\ControlPanel\NameSpace\{025A5937-A6BE-4686-A844-36FE4BEC8B6D}" -Name "PreferredPlan" -Type "String" -Value 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location = Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OptimalLayout"
If ($Location -eq "True"){
	$Value = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\OptimalLayout")."EnableAutoLayout"
	If ($Value -ne "0"){
		Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OptimalLayout" -Name "EnableAutoLayout" -Type "String" -Value 0 -Verbose
	}
}
ElseIf ($Location -ne "True"){
    New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OptimalLayout" -Verbose
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OptimalLayout" -Name "EnableAutoLayout" -Type "String" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")."NoRemoteRecursiveEvents"
If ($Value -ne "1"){
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoRemoteRecursiveEvents" -Type "DWord" -Value 1
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location1 = Test-Path "HKLM:\Software\Policies\Microsoft\Internet Explorer"
If ($Location1 -eq "True"){
    $Location2 = Test-Path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main"
    If ($Location2 -eq "True"){
        $Value =(Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main")."DisableFirstrunCustomize"
        If ($Value -ne "1"){
            Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main" -Name "DisableFirstrunCustomize" -Type "DWord" -Value 1 -Verbose
        }
    }
    ElseIf ($Location2 -ne "True"){
        New-Item -Path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main" -Verbose
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main" -Name "DisableFirstrunCustomize" -Type "DWord" -Value 1 -Verbose
    }
}
ElseIf ($Location1 -ne "True"){
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Internet Explorer" -Verbose
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main" -Verbose
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main" -Name "DisableFirstrunCustomize" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location1 = Test-Path "HKLM:\Software\Policies\Microsoft\SQMClient"
If ($Location1 -eq "True"){
    $Location2 = Test-Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows"
    If ($Location2 -eq "True"){
        $Value =(Get-ItemProperty "HKLM:\Software\Policies\Microsoft\SQMClient\Windows")."CEIPEnable"
        If ($Value -ne "0"){
            Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Type "DWord" -Value 0 -Verbose
        }
    }
    ElseIf ($Location2 -ne "True"){
        New-Item -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Verbose
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Type "DWord" -Value 0 -Verbose
    }
}
ElseIf ($Location1 -ne "True"){
    New-Item -Path "HKLM:\Software\Policies\Microsoft\SQMClient" -Verbose
    New-Item -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Verbose
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\CrashControl")."CrashDumpEnabled"
If ($Value -ne "0"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)
		
$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\CrashControl")."LogEvent"
If ($Value -ne "1"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\CrashControl" -Name "LogEvent" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)
		
$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\CrashControl")."SendAlert"
If ($Value -ne "0"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\CrashControl" -Name "SendAlert" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\FileSystem")."NtfsDisableLastAccessUpdate"
If ($Value -ne "1"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Print\Providers")."EventLog"
If ($Value -ne "1"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Print\Providers" -Name "EventLog" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Session Manager\Executive")."AdditionalCriticalWorkerThreads"
If ($Value -ne "64"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Executive" -Name "AdditionalCriticalWorkerThreads" -Type "DWord" -Value 64 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management")."MoveImages"
If ($Value -ne "0"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name "MoveImages" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management")."ClearPageFileAtShutdown"
If ($Value -ne "0"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Control\Windows")."ErrorMode"
If ($Value -ne "2"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Windows" -Name "ErrorMode" -Type "DWord" -Value 2 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\Disk")."TimeOutValue"
If ($Value -ne "0x000000c8"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Disk" -Name "TimeOutValue" -Type "DWord" -Value 0x000000c8 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters")."FileInfoCacheEntriesMax"
If ($Value -ne "1024"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "FileInfoCacheEntriesMax" -Type "DWord" -Value 1024 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters")."DirectoryCacheEntriesMax"
If ($Value -ne "1024"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "DirectoryCacheEntriesMax" -Type "DWord" -Value 1024 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters")."FileNotFoundCacheEntriesMax"
If ($Value -ne "2048"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "FileNotFoundCacheEntriesMax" -Type "DWord" -Value 2048 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters")."DormantFileLimit"
If ($Value -ne "256"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "DormantFileLimit" -Type "DWord" -Value 256 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters")."DisableBandwidthThrottling"
If ($Value -ne "1"){
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "DisableBandwidthThrottling" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy")."DeleteUserAppContainersOnLogoff"
If ($Value -ne "1"){
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy" -Name "DeleteUserAppContainersOnLogoff" -Type "DWord" -Value 1 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Value = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power")."HibernateEnabled"
If ($Value -ne "0"){
	Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

$Location = Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense"
If ($Location -eq "True"){
	$Value = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense")."AllowStorageSenseGlobal"
	If ($Value -ne "0"){
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -Name "AllowStorageSenseGlobal" -Type "DWord" -Value 0 -Verbose
	}
}
Elseif ($Location -ne "True"){
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -Verbose
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\StorageSense" -Name "AllowStorageSenseGlobal" -Type "DWord" -Value 0 -Verbose
}

$VDIOPsCounter++
Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)

If ($OSMajorVersion -like "*Windows 10*") {
	$Value = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System")."EnableFirstLogonAnimation"
	If ($Value -ne "0"){
		Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableFirstLogonAnimation" -Type "DWord" -Value 0 -Verbose
	}
	
	$VDIOPsCounter++
	Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)
	
	$Location = Test-Path "HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo"
	If ($Location -eq "True") {
		$Value =(Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo")."DisabledByGroupPolicy"
		If ($Value -ne "1"){
			Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type "DWord" -Value 1 -Verbose
		}
	}
	ElseIf ($Location -ne "True") {
		New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo" -Verbose
		Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type "DWord" -Value 1 -Verbose
	}
	
	$VDIOPsCounter++
	Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)
	
	$Location = Test-Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent"
	If ($Location -eq "True") {
		$Value =(Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\CloudContent")."DisableWindowsConsumerFeatures"
		If ($Value -ne "1"){
			Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1 -Verbose
		}
	}
	ElseIf ($Location -ne "True") {
		New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Verbose
		Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type "DWord" -Value 1 -Verbose
	}
	
	$VDIOPsCounter++
	Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)
	
	$Location = Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization"
	If ($Location -eq "True") {
		$Value =(Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\Personalization")."NoLockScreenSlideShow"
		If ($Value -ne "1"){
			Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreenSlideShow" -Type "DWord" -Value 1 -Verbose
		}
	}
	ElseIf ($Location -ne "True") {
		New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Verbose
		Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreenSlideShow" -Type "DWord" -Value 1 -Verbose
	}
	
	$VDIOPsCounter++
	Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete (($VDIOpsCounter / $VDIOps) * 100)
}

Write-Progress -Activity "Generic VDI Optimizations" -Id 170 -ParentId 10 -PercentComplete 100 -Completed

#endregion Generic VDI optimizations

$OSOpsCounter++
Write-Progress -Activity "Windows Optimizations - Operating System" -Id 10 -ParentId 0 -PercentComplete 100 -Completed

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

"$(Get-TimeStamp)            End of $OSMajorVersion $OSMinorVersion Optimization."

<#
	Application
	Specific
	Optimizations
#>

$AppOpsCounter = 0
$Apps = 8

Write-Progress -Activity "Application Optimizations" -Id 20 -ParentId 0 -PercentComplete 0

"$(Get-TimeStamp)            Application Optimization Starts Now."

#region Application Optimizations Template
<#
	Application Template

	If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\(Executable Name) {
		"$(Get-TimeStamp)            (Application) Installed.  Optimizing (Application)."
		Disable Services
		Disable Scheduled Tasks
		Change/Add/Remove Registry Keys
	}
	
	Disable Service
	
	Stop-Service (Service Name) -Force
	Set-Service (Service Name) -StartupType Disabled
	
	Disable Scheduled Tasks
	
	Disable-ScheduledTask -TaskName "(TaskName)"
	
	Remove Registry Value
	
	Remove -ItemProperty -Path “(RegistryValueLocation)” -Name “(RegistryValueName)”
	
	Add Registry Value
	
	Set-ItemProperty -Path "(RegistryValueLocation" -Name "(RegistryValueName)" -Type "(RegistryValueType)" -Value (RegistryValue)
#>
#endregion Application Optimizations Template

#region Google Chrome Optimizations
<#
	Google
	Chrome
	Optimizations
#>

If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe') {
	Write-Progress -Activity "Optimizing Google Chrome" -Id 210 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            Google Chrome Installed.  Optimizing Google Chrome."
	Stop-Service GoogleChromeElevationService -Force -Verbose
	"$(Get-TimeStamp)            GoogleChromeElevationService Stopped."
	Set-Service GoogleChromeElevationService -StartupType Disabled -Verbose
	"$(Get-TimeStamp)            GoogleChromeElevationService Disabled."
	Stop-Service gupdate -Force -Verbose
	"$(Get-TimeStamp)            gupdate Service Stopped."
	Set-Service gupdate -StartupType Disabled -Verbose
	"$(Get-TimeStamp)            gupdate Service Disabled."
	Stop-Service gupdatem -Force -Verbose
	"$(Get-TimeStamp)            gupdatem Service Stopped."
	Set-Service gupdatem -StartupType Disabled -Verbose
	"$(Get-TimeStamp)            gupdatem Service Disabled."
	Disable-ScheduledTask -TaskName "GoogleUpdateTaskMachineCore" -Verbose
	"$(Get-TimeStamp)            GoogleUpdateTaskMachineCore Scheduled Task Disabled."
	Disable-ScheduledTask -TaskName "GoogleUpdateTaskMachineUA" -Verbose
	"$(Get-TimeStamp)            GoogleUpdateTaskMachineUA Scheduled Task Disabled."
	Remove-ItemProperty -Path “HKLM:\Software\Microsoft\Active Setup\Installed Components\{8A69D345-D564-463c-AFF1-A69D9E530F96}” -Name “StubPath” -Verbose
	"$(Get-TimeStamp)            Google Chrome Active Setup Optimized."
	
	$Location1 = Test-Path "HKLM:\Software\Policies\Google"

	If ($Location1 -eq "True") {
		$Location2 = Test-Path "HKLM:\Software\Policies\Google\Chrome"
		If ($Location2 -eq "True") {
			$Value1 =(Get-ItemProperty "HKLM:\Software\Policies\Google\Chrome")."ChromeCleanupEnabled"
			$Value2 =(Get-ItemProperty "HKLM:\Software\Policies\Google\Chrome")."ChromeCleanupReportingEnabled"
			If ($Value1 -ne "0"){
				Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupEnabled" -Type "DWord" -Value 0 -Verbose
				"$(Get-TimeStamp)            Google Software Reporter Tool ChromeCleanupEnabled Optimized."
			}
			If ($Value2 -ne "0"){
				Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupReportingEnabled" -Type "DWord" -Value 0 -Verbose
				"$(Get-TimeStamp)            Google Software Reporter Tool ChromeCleanupReportingEnabled Optimized."
			}
		}
		ElseIf ($Location2 -ne "True") {
			New-Item -Path "HKLM:\Software\Policies\Google\Chrome" -Verbose
			Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupEnabled" -Type "DWord" -Value 0 -Verbose
			"$(Get-TimeStamp)            Google Software Reporter Tool ChromeCleanupEnabled Optimized."
			Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupReportingEnabled" -Type "DWord" -Value 0 -Verbose
			"$(Get-TimeStamp)            Google Software Reporter Tool ChromeCleanupReportingEnabled Optimized."
		}
	}
	ElseIf ($Location1 -ne "True") {
		New-Item -Path "HKLM:\Software\Policies\Google" -Verbose
		New-Item -Path "HKLM:\Software\Policies\Google\Chrome" -Verbose
		Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupEnabled" -Type "DWord" -Value 0 -Verbose
		"$(Get-TimeStamp)            Google Software Reporter Tool ChromeCleanupEnabled Optimized."
		Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupReportingEnabled" -Type "DWord" -Value 0 -Verbose
		"$(Get-TimeStamp)            Google Software Reporter Tool ChromeCleanupReportingEnabled Optimized."
    }
	Write-Progress -Activity "Optimizing Google Chrome" -Id 210 -ParentId 20 -PercentComplete 100 -Completed	
	"$(Get-TimeStamp)            Google Chrome Optimized."
}

<#
	Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupEnabled" -Type "DWord" -Value 0
	Set-ItemProperty -Path "HKLM:\Software\Policies\Google\Chrome" -Name "ChromeCleanupReportingEnabled" -Type "DWord" -Value 0
	Disables Google Software Reporter Tool
	https://www.ghacks.net/2018/01/20/how-to-block-the-chrome-software-reporter-tool-software_reporter_tool-exe/
	Only works If machine is domain joined
	https://www.chromium.org/administrators/policy-list-3#ChromeCleanupEnabled
#>

#endregion Google Chrome Optimizations

$AppOpsCounter++
Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete (($AppOpsCounter / $Apps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Microsoft Edge Optimizations
<#
	Microsoft
	Edge
	(Chromium)
	Optimizations
#>

If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe') {
	Write-Progress -Activity "Optimizing Microsoft Edge" -Id 220 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            Microsoft Edge Installed.  Optimizing Microsoft Edge."
	Stop-Service MicrosoftEdgeElevationService -Force -Verbose
	"$(Get-TimeStamp)            MicrosoftEdgeElevationService Stopped."
	Set-Service MicrosoftEdgeElevationService -StartupType Disabled -Verbose
	"$(Get-TimeStamp)            MicrosoftEdgeElevationService Disabled."
	Stop-Service edgeupdate -Force -Verbose
	"$(Get-TimeStamp)            edgeupdate Service Stopped."
	Set-Service edgeupdate -StartupType Disabled -Verbose
	"$(Get-TimeStamp)            edgeupdate Service Disabled."
	Stop-Service edgeupdatem -Force -Verbose
	"$(Get-TimeStamp)            edgeupdatem Service Stopped."
	Set-Service edgeupdatem -StartupType Disabled -Verbose
	"$(Get-TimeStamp)            edgeupdatem Service Disabled."
	Disable-ScheduledTask -TaskName "MicrosoftEdgeUpdateTaskMachineCore" -Verbose
	"$(Get-TimeStamp)            MicrosoftEdgeUpdateTaskMachineCore Scheduled Task Disabled."
	Disable-ScheduledTask -TaskName "MicrosoftEdgeUpdateTaskMachineUA" -Verbose
	"$(Get-TimeStamp)            MicrosoftEdgeUpdateTaskMachineCore Scheduled Task Disabled."
	Remove-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}” -Name “StubPath” -ErrorAction SilentlyContinue -Verbose
	"$(Get-TimeStamp)            Microsoft Edge Active Setup Optimized."
	Remove-ItemProperty -Path “HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce” -Name “msedge_cleanup_{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}” -ErrorAction SilentlyContinue -Verbose
	"$(Get-TimeStamp)            Microsoft Edge RunOnce Key Optimized."
	$Location = Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
	If ($Location -eq "True"){
		$Value = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge")."HideFirstRunExperience"
		If ($Value -ne "1"){
			Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Type "DWord" -Value 1 -Verbose
		}
	}
	Elseif ($Location -ne "True"){
		New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Verbose
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Type "DWord" -Value 1 -Verbose
	}
	"$(Get-TimeStamp)            Microsoft Edge First Run Experience Optimized."
	Write-Progress -Activity "Optimizing Microsoft Edge" -Id 220 -ParentId 20 -PercentComplete 100 -Completed
	"$(Get-TimeStamp)            Microsoft Edge Optimized."
}

#endregion Microsoft Edge Optimizations

$AppOpsCounter++
Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete (($AppOpsCounter / $Apps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Mozilla Firefox Optimizations
<#
	Mozilla
	Firefox 88.0+
	Optimizations
#>

If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\firefox.exe') {
	Write-Progress -Activity "Optimizing Mozilla Firefox" -Id 230 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            Mozilla Firefox Installed.  Optimizing Mozilla Firefox."
	Stop-Service MozillaMaintenance -Force -ErrorAction SilentlyContinue -Verbose
	"$(Get-TimeStamp)            MozillaMaintenance Service Stopped."
	Set-Service MozillaMaintenance -StartupType Disabled -ErrorAction SilentlyContinue -Verbose
	"$(Get-TimeStamp)            MozillaMaintenance Service Disabled."
	Get-ScheduledTask -TaskName *Firefox* | Disable-ScheduledTask -Verbose
	"$(Get-TimeStamp)            Firefox Scheduled Tasks Disabled."
	Write-Progress -Activity "Optimizing Mozilla Firefox" -Id 230 -ParentId 20 -PercentComplete 100 -Completed
	"$(Get-TimeStamp)            Mozilla Firefox Optimized."
}

<#
	Mozilla Firefox utilizes config and ini files to customize the application, rather then registry keys.
	https://stealthpuppy.com/prepare-mozilla-firefox-for-enterprise-deployment-and-virtualization/ explains it further.  The link is almost 10 years old, but Firefox hasn't changed in that long.
	My recommendation, follow the link above, create the appropriate configuration files, then place them in the correct folder for everybody to utilize.
#>

#endregion Mozilla Firefox Optimizations

$AppOpsCounter++
Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete (($AppOpsCounter / $Apps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Adobe Reader DC Optimizations
<#
	Adobe
	Reader DC
	Optimizations
#>

If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\AcroRd32.exe'){
	Write-Progress -Activity "Optimizing Adobe Reader" -Id 240 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            Adobe Reader Installed.  Optimizing Adobe Reader."
	Stop-Service AdobeARMservice -Force -Verbose
	"$(Get-TimeStamp)            AdobeARMservice Stopped."
	Set-Service AdobeARMservice -StartupType Disabled -Verbose
	"$(Get-TimeStamp)            AdobeARMservice Disabled."
	Disable-ScheduledTask -TaskName "Adobe Acrobat Update Task" -Verbose
	"$(Get-TimeStamp)            Adobe Acrobat Update Task Scheduled Task Disabled."
	New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Adobe" -Verbose
	New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Adobe\Acrobat Reader" -Verbose
	New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Adobe\Acrobat Reader\DC" -Verbose
	New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Adobe\Acrobat Reader\DC\FTEDialog" -Verbose
	Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\DC\FTEDialog" -Name "iFTEVersion" -Type "DWord" -Value 10 -Verbose
	Set-ItemProperty -Path "HKLM:\Software\Adobe\Acrobat Reader\DC\FTEDialog" -Name "iLastCardShown" -Type "DWord" -Value 0 -Verbose
	New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Adobe\Acrobat Reader\DC\AdobeViewer" -Verbose
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Adobe\Acrobat Reader\DC\AdobeViewer" -Name "EULA" -Type "DWord" -Value 1 -Verbose
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bAcroSuppressUpsell" -Type "DWord" -Value 1 -Verbose
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bProtectedMode" -Type "DWord" -Value 0 -Verbose
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bUpdater" -Type "DWord" -Value 0 -Verbose
    New-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" -Verbose
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" -Name "bUpdater" -Type "DWord" -Value 0 -Verbose
	Write-Progress -Activity "Optimizing Adobe Reader" -Id 240 -ParentId 20 -PercentComplete 100 -Completed
	"$(Get-TimeStamp)            Adobe Reader Optimized."
}

<#
	The following are Best Practice Adobe Reader DC Registry Values for VDI

	Disables the Reader Tour at first startup
	Set-ItemProperty -Path "HKLM:\Software\WOW6432Node\Adobe\Acrobat Reader\DC\FTEDialog" -Name "iFTEVersion" -Type "DWord" -Value a

	Agrees to the EULA
	Set-ItemProperty -Path "HKLM:\Software\Wow6432Node\Policies\Adobe\Acrobat Reader\DC\AdobeViewer" -Name "EULA" -Type "DWord" -Value 1

	Prevents the upsell "feature" of Reader, prompting users to buy Acrobat
	Set-ItemProperty -Path "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bAcroSuppressUpsell" -Type "DWord" -Value 1

	Disables Protected Mode, which sandboxes Acrobat and Reader processes
	Set-ItemProperty -Path "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bProtectedMode" -Type "DWord" -Value 0

	Removes the 'Check for Updates' option from the Help menu and Locks the Updater
	Set-ItemProperty -Path "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" -Name "bUpdater" -Type "DWord" -Value 0

	Disables services and service component updates
	Set-ItemProperty -Path "HKLM:\Software\WOW6432Node\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" -Name "bUpdater" -Type "DWord" -Value 0
#>

#endregion Adobe Reader DC Optimizations

$AppOpsCounter++
Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete (($AppOpsCounter / $Apps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Java Runtime Environment v8.x Optimizations
<#
	Java
	Runtime Environment
	v8.x
	Optimizations
#>

If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\javaws.exe'){
	Write-Progress -Activity "Optimizing Java Runtime Environment" -Id 250 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            Java Runtime Environment Installed.  Optimizing Java Runtime Environment."
	Remove-ItemProperty -Path “HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run” -Name “SunJavaUpdateSched” -Verbose
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "EnableAutoUpdateCheck" -Type "DWord" -Value 0 -Verbose
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "EnableJavaUpdate" -Type "DWord" -Value 0 -Verbose
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "NotifyDownload" -Type "DWord" -Value 0 -Verbose
	Write-Progress -Activity "Optimizing Java Runtime Environment" -Id 250 -ParentId 20 -PercentComplete 100 -Completed
	"$(Get-TimeStamp)            Java Runtime Environment Optimized."
}

<#
	Removes the Run Value for Updating Java
	Remove-ItemProperty -Path “HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run” -Name “SunJavaUpdateSched”

	Disables Java Auto Update Check in the Java Policy registry location
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "EnableAutoUpdateCheck" -Type "DWord" -Value 0

	Disables Java Updates in the Java Policy registry location
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "EnableJavaUpdate" -Type "DWord" -Value 0

	Disables Java Download Notification in the Java Policy registry location
	Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\JavaSoft\Java Update\Policy" -Name "NotifyDownload" -Type "DWord" -Value 0
#>

#endregion Java Runtime Environment v8.x Optimizations

$AppOpsCounter++
Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete (($AppOpsCounter / $Apps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Microsoft OneDrive Optimizations
<#
	Microsoft
	OneDrive
	Optimizations
#>

If (Test-Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OneDriveFileLauncher.exe'){
	Write-Progress -Activity "Optimizing Microsoft OneDrive" -Id 260 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            OneDrive Installed.  Optimizing OneDrive."
	Get-ScheduledTask -TaskName *OneDrive* | Disable-ScheduledTask -Verbose
	"$(Get-TimeStamp)            All OneDrive Scheduled Tasks Disabled."
	Write-Progress -Activity "Optimizing Microsoft OneDrive" -Id 260 -ParentId 20 -PercentComplete 100 -Completed
	"$(Get-TimeStamp)            OneDrive Optimized."
}

#endregion Microsoft OneDrive Optimizations

$AppOpsCounter++
Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete (($AppOpsCounter / $Apps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Microsoft Office Optimizations
<#
	Microsoft
	Office
	Optimizations
#>

# (NOT ENABLED BY DEFAULT) - Future Use - If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\excel.exe'
# (NOT ENABLED BY DEFAULT) - Future Use - If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Outlook.exe'
# (NOT ENABLED BY DEFAULT) - Future Use - If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\powerpnt.exe'
# (NOT ENABLED BY DEFAULT) - Future Use - If (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Winword.exe'

#endregion Microsoft Office Optimizations

#region Microsoft Skype Optimizations
<#
	Microsoft
	Skype
	Optimizations
#>

$Location1 = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\lync.exe"
If ($Location1 -eq "True"){
	Write-Progress -Activity "Optimizing Microsoft Skype" -Id 270 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            Skype Installed.  Optimizing Skype."
    Remove-ItemProperty -Path “HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run” -Name “Lync” -Verbose
	"$(Get-TimeStamp)            Skype Run Key Optimized."
	Write-Progress -Activity "Optimizing Microsoft Skype" -Id 270 -ParentId 20 -PercentComplete 100 -Completed
	"$(Get-TimeStamp)            Skype Optimized."
}

#endregion Microsoft Skype Optimizations

$AppOpsCounter++
Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete (($AppOpsCounter / $Apps) * 100)

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Microsoft Teams Optimizations
<#
	Microsoft
	Teams
	Optimizations
#>

$Location1 = Test-Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
If ($Location1 -eq "True"){
	Write-Progress -Activity "Optimizing Microsoft Teams" -Id 280 -ParentId 20 -PercentComplete 0
    "$(Get-TimeStamp)            Microsoft Teams Installed.  Optimizing Microsoft Teams."
    $Value1 =(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration")."TeamsAddon"
        If ($Value1 -eq "INSTALLED"){
            Remove-ItemProperty -Path “HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run” -Name “TeamsMachineInstaller” -Verbose
			"$(Get-TimeStamp)            Microsoft Teams WOW6432Node Run Key Optimized."
			Remove-ItemProperty -Path “HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run” -Name “com.squirrel.Teams.Teams” -Verbose
			"$(Get-TimeStamp)            Microsoft Teams Run Key Optimized."
			Write-Progress -Activity "Optimizing Microsoft Teams" -Id 280 -ParentId 20 -PercentComplete 100 -Completed
			"$(Get-TimeStamp)            Microsoft Teams Optimized."
        }
}

#endregion Microsoft Teams Optimizations

Write-Progress -Activity "Windows Optimizations - Applications" -Id 20 -ParentId 0 -PercentComplete 100 -Completed

"$(Get-TimeStamp)            Application Optimization Complete."

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Generic OS Optimizations
<#
	Generic
	Operating System
	Optimizations
#>

#region Local File Cleanup
<#
	Local File Cleanup
#>

Write-Progress -Activity "Windows Optimizations - Generic" -Id 30 -ParentId 0 -PercentComplete 0

Write-Progress -Activity "Local File Cleanup" -Id 310 -ParentId 30 -PercentComplete 0

"$(Get-TimeStamp)            Local File Cleanup Started."

Start-Process -Wait "$env:SystemRoot\System32\cleanmgr.exe" -ArgumentList "/sagerun:1" -Verbose

Write-Progress -Activity "Local File Cleanup" -Id 310 -ParentId 30 -PercentComplete 33

$IEFolders = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$IECookies = $IEFolders.Cookies
$IECache = $IEFolders.Cache
$IEHistory = $IEFolders.History

$Paths = @(

"$IECookies",
"$IECache",
"$IEHistory",
"C:\Windows\Temp\*",
"C:\windows\Prefetch\*",
"C:\windows\SoftwareDistribution\Download\*",
"$env:LOCALAPPDATA\Temp\*"

)

$Exclusions = @(

"Costura",
"ProfileUnity",
"FXSAPIDebugLogFile*",
"FXSTIFFDebugLogFile*"

)

ForEach ($Path in $Paths) {
	If ($Path -eq "C:\Windows\Temp\*"){
		Get-ChildItem -path $Path -Exclude $Exclusions | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue -Verbose
		"-----------------------------------------------------------------------"
	}
	ElseIf ($Path -ne "C:\Windows\Temp\*"){
		Get-ChildItem -path $Path | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue -Verbose
		"-----------------------------------------------------------------------"
	}
}

Write-Progress -Activity "Local File Cleanup" -Id 310 -ParentId 30 -PercentComplete 66

dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase

Write-Progress -Activity "Local File Cleanup" -Id 310 -ParentId 30 -PercentComplete 100 -Completed

Write-Progress -Activity "Windows Optimizations - Generic" -Id 30 -ParentId 0 -PercentComplete 25

"$(Get-TimeStamp)            Local File Cleanup Completed."
"-----------------------------------------------------------------------"

#endregion Local File Cleanup

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Storage Optimizations
<#
	Storage
	Optimizations
#>

Write-Progress -Activity "Storage Optimizations" -Id 320 -ParentId 30 -PercentComplete 0

"$(Get-TimeStamp)            Starting Storage Optimizations."

<#
	The below portion of the script runs a defrag of the hard drive
	If you are using an SSD drive, this portion is unnecessary
	https://www.crucial.com/articles/about-ssd/should-you-defrag-an-ssd
	If this is a Virtual Machine using an underlying Three Tier or HCI infrastructure, this portion is unnecessary
	https://blogs.vmware.com/vsphere/2011/09/should-i-defrag-my-guest-os.html
	If you are using an HDD on a physical machine or a local Virtual Machine, this portion will helpful
	In the latter case, please enable the following section
#>

<#
Set-Service defragsvc -StartupType Automatic -Verbose
Start-Service defragsvc -Verbose
defrag c: /U /V -Verbose
"$(Get-TimeStamp)            Defrag Complete."
"-----------------------------------------------------------------------"
Stop-Service defragsvc -Force -Verbose
Set-Service defragsvc -StartupType Disabled -Verbose
#>

Write-Progress -Activity "Storage Optimizations" -Id 320 -ParentId 30 -PercentComplete 33

vssadmin delete shadows /All /Quiet
"$(Get-TimeStamp)            Volume Shadow Copies Deleted."
"-----------------------------------------------------------------------"

Write-Progress -Activity "Storage Optimizations" -Id 320 -ParentId 30 -PercentComplete 66

If ((Get-Partition).Where({$_.Type -eq "Unknown"})) {
	"$(Get-TimeStamp)            Recovery Partition Found."
	"-----------------------------------------------------------------------"
	(Get-Partition).Where({$_.type -eq "unknown"}) | Remove-Partition -confirm:$false -Verbose
	"$(Get-TimeStamp)            Recovery Partition Removed."
	"-----------------------------------------------------------------------"
}
Else {
	"$(Get-TimeStamp)            No Recovery Partition Found."
	"-----------------------------------------------------------------------"
}

Write-Progress -Activity "Storage Optimizations" -Id 320 -ParentId 30 -PercentComplete 100 -Completed

Write-Progress -Activity "Windows Optimizations - Generic" -Id 30 -ParentId 0 -PercentComplete 50

"$(Get-TimeStamp)            Storage Optimizations Complete."
"-----------------------------------------------------------------------"

#endregion Storage Optimizations

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region .Net Runtime Updates
<#
	.Net Runtime
	Updates
#>

Write-Progress -Activity ".NET Updates" -Id 330 -ParentId 30 -PercentComplete 0
Write-Progress -Activity "32bit .NET Updates" -Id 331 -ParentId 330 -PercentComplete 0

"$(Get-TimeStamp)            Starting 32bit .NET Updates."
"$(Get-TimeStamp)            Executing Queued Items"

& 'C:\Windows\microsoft.net\framework\v4.0.30319\ngen.exe' executeQueuedItems -Verbose

"$(Get-TimeStamp)            Running Updates"

& 'C:\Windows\microsoft.net\framework\v4.0.30319\ngen.exe' update /force -Verbose

Write-Progress -Activity "32bit .NET Updates" -Id 331 -ParentId 330 -PercentComplete 100 -Completed

"$(Get-TimeStamp)            32bit .NET Updates Complete."
"-----------------------------------------------------------------------"

Write-Progress -Activity ".NET Updates" -Id 330 -ParentId 30 -PercentComplete 50
Write-Progress -Activity "64bit .NET Updates" -Id 332 -ParentId 330 -PercentComplete 0

"$(Get-TimeStamp)            Starting 64bit .NET Updates."
"$(Get-TimeStamp)            Executing Queued Items"

& 'C:\Windows\microsoft.net\framework64\v4.0.30319\ngen.exe' executeQueuedItems -Verbose

"$(Get-TimeStamp)            Running Updates"

& 'C:\Windows\microsoft.net\framework64\v4.0.30319\ngen.exe' update /force -Verbose

Write-Progress -Activity "64bit .NET Updates" -Id 332 -ParentId 30 -PercentComplete 100 -Completed

"$(Get-TimeStamp)            64bit .NET Updates Complete."
"$(Get-TimeStamp)            .NET Updates Complete."
"-----------------------------------------------------------------------"

Write-Progress -Activity ".NET Updates" -Id 330 -ParentId 30 -PercentComplete 100 -Completed

#endregion .Net Runtime Updates

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

#region Housekeeping Tasks
<#
	Housekeeping Tasks
#>

Write-Progress -Activity "Housekeeping Tasks" -Id 340 -ParentId 30 -PercentComplete 0

"$(Get-TimeStamp)            Starting Housekeeping Tasks."

ipconfig /flushdns

Write-Progress -Activity "Housekeeping Tasks" -Id 340 -ParentId 30 -PercentComplete 33

netsh interface ip delete arpcache

Write-Progress -Activity "Housekeeping Tasks" -Id 340 -ParentId 30 -PercentComplete 66

Get-EventLog -LogName * | ForEach {Clear-EventLog $_.Log}

Write-Progress -Activity "Housekeeping Tasks" -Id 340 -ParentId 30 -PercentComplete 100 -Completed

Write-Progress -Activity "Windows Optimizations - Generic" -Id 30 -ParentId 0 -PercentComplete 100 -Completed

"$(Get-TimeStamp)            Housekeeping Tasks Complete."

#endregion Housekeeping Tasks

$OpsCounter++
Write-Progress -Activity "Windows Optimizations" -Id 0 -PercentComplete (($OpsCounter / $Ops) * 100)

<#
	Reboot Request
	Enable If you desire a reboot
#>

"Your OS requires a restart: $RebootRequiredStatus"

#"$(Get-TimeStamp)            Kicking off Reboot."
#Restart-Computer -Force

Write-Progress -Activity "Windows Optimizations - Generic OS" -Id 30 -ParentId 0 -PercentComplete 100 -Completed

#endregion  Generic OS Optimizations

Write-Progress -Activity "Windows Optimizations" -Id 0 "Overall Progress" -PercentComplete 100 -Completed

"$(Get-TimeStamp)            Optimization Script Complete."

#region Stop Script Timer

$ScriptElapsedMins = $ScriptStopWatch.Elapsed.Minutes
$ScriptElapsedSecs = $ScriptStopWatch.Elapsed.Seconds

"$(Get-TimeStamp)			 WOSTT took $ScriptElapsedMins minutes and $ScriptElapsedSecs seconds to complete."

$ScriptStopWatch.Stop()

#endregion Stop Script Timer

Stop-Transcript