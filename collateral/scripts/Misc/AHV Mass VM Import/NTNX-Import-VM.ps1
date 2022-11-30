#region Connection Functions

############################################################
##
## Function: NTNX-Connect-HYP
## Author: Steven Poitras
## Description: Connect to Hypervisor manager function
## Language: PowerShell
##
############################################################
function NTNX-Connect-HYP {
<#
.NAME
	NTNX-Connect-HYP
.SYNOPSIS
	Connect to Hypervisor manager function
.DESCRIPTION
	Connect to Hypervisor manager function
.NOTES
	Authors:  thedude@nutanix.com
	
	Logs: C:\Users\<USERNAME>\AppData\Local\Temp\NutanixCmdlets\logs
.LINK
	www.nutanix.com
.EXAMPLE
    NTNX-Connect-HYP -IP "99.99.99.99.99" -User "BlahUser" -Type VC
#> 
	Param(
	    [parameter(mandatory=$true)][AllowNull()]$IP,
		
		[parameter(mandatory=$false)][AllowNull()]$Type,
		
		[parameter(mandatory=$false)][AllowNull()]$credential
	)

	begin{
		$hypType = "VC","SCVMM"
	
		# Make sure requried snappins are installed / loaded
		$loadedSnappins = Get-PSSnapin
		
		# If no IP passed prompt for IP
		if ([string]::IsNullOrEmpty($IP)) {
			$IP = Read-Host "Please enter a IP or hostname for the management Server"
		}
		
		# If no type passed prompt for type
		if ([string]::IsNullOrEmpty($Type)) {
			$Type = NTNX-Build-Menu -Title "Please select a management server type" -Data $hypType
		}
		
		# If values not set use defaults
		if ([string]::IsNullOrEmpty($credential)) {
			Write-Host "No admin credential passed, prompting for input..."
			$credential = (Get-Credential -Message "Please enter the vCenter Server credentials <admin/*******>")
		}

	}
	process {
		if ($Type -eq $hypType[0]) {
			# Make sure snappin is loaded
			if ($loadedSnappins.name -notcontains "VMware.VimAutomation.Core") {
				# Try to load snappin
				Add-PSSnapin VMware.VimAutomation.Core
				
				# Refresh list of loaded snappins
				$loadedSnappins = Get-PSSnapin
				
				if ($loadedSnappins.name -notcontains "VMware.VimAutomation.Core") {
					# Try to load snappin
					Write-Host "PowerCLI snappin not installed or loaded, exiting..."
					break
				}
			}	
			
			# Check if connection already exists
			if ($($global:DefaultVIServers | where {$_.Name -Match $IP}).IsConnected -ne "True") {
				# Connect to vCenter Server
				Write-Host "Connecting to vCenter Server ${IP} as ${credential.UserName}..."
				$connObj = Connect-VIServer $IP -User $($credential.UserName.Trim("\")) `
					-Password $(([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password))))
			} else {  #Already connected to server
				Write-Host "Already connected to server ${IP}, continuing..."
			}
		} elseif ($Type -eq $hypType[1]) {
			# To be input
		}
		
	}
	end {
		$hypServerObj = New-Object PSCustomObject -Property @{
			IP = $IP
			Type = $Type
			Credential = $credential
			connObj = $connObj
		}
		
		return $hypServerObj
	}
}

############################################################
##
## Function: NTNX-Connect-NTNX
## Author: Steven Poitras
## Description: Connect to NTNX function
## Language: PowerShell
##
############################################################
function NTNX-Connect-NTNX {
<#
.NAME
	NTNX-Connect-NTNX
.SYNOPSIS
	Connect to NTNX function
.DESCRIPTION
	Connect to NTNX function
.NOTES
	Authors:  thedude@nutanix.com
	
	Logs: C:\Users\<USERNAME>\AppData\Local\Temp\NutanixCmdlets\logs
.LINK
	www.nutanix.com
.EXAMPLE
    NTNX-Connect-NTNX -IP "99.99.99.99.99" -User "BlahUser"
#> 
	Param(
	    [parameter(mandatory=$true)][AllowNull()]$ip,
		
		[parameter(mandatory=$false)][AllowNull()]$credential
	)

	begin{
		# Make sure requried snappins are installed / loaded
		$loadedSnappins = Get-PSSnapin
		
		if ($loadedSnappins.name -notcontains "NutanixCmdletsPSSnapin") {
			Write-Host "Nutanix snappin not installed or loaded, trying to load..."
			
			# Try to load snappin
			Add-PSSnapin NutanixCmdletsPSSnapin
			
			# Refresh list of loaded snappins
			$loadedSnappins = Get-PSSnapin
			
			if ($loadedSnappins.name -notcontains "NutanixCmdletsPSSnapin") {
				Write-Host "Nutanix snappin not installed or loaded, exiting..."
				break
			}
		}
		
		# If values not set use defaults
		if ([string]::IsNullOrEmpty($credential.UserName)) {
			Write-Host "No Nutanix user passed, using default..."
			$credential = (Get-Credential -Message "Please enter the Nutanix Prism credentials <admin/*******>")
		}

	}
	process {
		# Check for connection and if not connected try to connect to Nutanix Cluster
		if ([string]::IsNullOrEmpty($IP)) { # Nutanix IP not passed, gather interactively
			$IP = Read-Host "Please enter a IP or hostname for the Nutanix cluter"
		}
		
		# If not connected, try connecting
		if ($(Get-NutanixCluster -Servers $IP -ErrorAction SilentlyContinue).IsConnected -ne "True") {  # Not connected
			Write-Host "Connecting to Nutanix cluster ${IP} as $($credential.UserName.Trim("\")) ..."
			$connObj = Connect-NutanixCluster -Server $IP -UserName $($credential.UserName.Trim("\")) `
				-Password $(([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)))) -AcceptInvalidSSLCerts -F
		} else {  # Already connected to server
			Write-Host "Already connected to server ${IP}, continuing..."
		}
	}
	end {
		$nxServerObj = New-Object PSCustomObject -Property @{
			IP = $IP
			Credential = $credential
			connObj = $connObj
		}
		
		return $nxServerObj
	}
}

#endregion
#region Helper Functions
function NTNX-Build-Menu {
<#
.NAME
	NTNX-Build-Menu
.SYNOPSIS
	Builds and menu and return the users selection
.DESCRIPTION
  Build a menu passing an array of values and retun the user's selection
.NOTES
	Authors:  VMware Dude
.LINK
	www.nutanix.com
.PARAMETER Title
  Menu title
.PARAMETER Data
  Array data used for menu options
.EXAMPLE
  NTNX-Build-Menu -Title "My Menu" -Data $MyArray
#>
   
Param(
	[parameter(Mandatory=$true)][string]$Title,
    [parameter(Mandatory=$true)][array]$Data,
    [parameter(Mandatory=$false)]$filter,
    [parameter(Mandatory=$false)][array]$EndObj
)
	if ([string]::IsNullOrEmpty($EndObj)) {
  		$EndObj = "DONE"
	}
	
	$Increment = 0
	$filteredData = $Data | select $filter
	$filteredData += $EndObj
	
	write-host ""
	write-host $Title
	$filteredData | %{
		$Increment +=1
		write-host "$Increment." $_
	}
	
	$index = (read-host "Please select an option [Example: 1]")
	
	if (!$index) {
		break
	} else {
		$index-=1
	}
  
	# Selection is valid
	if ($Data[$index]) {
		$selection = $Data[$index]
		write-host "You selected: $($selection | select $filter)"
	} elseif ($filteredData[$index]) { # Assuming last index was selected
		$selection = $filteredData[$index]
		Write-Host 	"You selected: $selection"
	} else {
		$selection = $EndObj
		Write-Host 	"Selection Invalid!"
	}

	return $selection
}
function NTNX-Map-Object {
<#
.NAME
	NTNX-Map-Object
.SYNOPSIS
	Maps objects from provided arrays
.DESCRIPTION
	Maps objects from provided arrays
.NOTES
	Authors:  The Dude
	
	Logs: C:\Users\<USERNAME>\AppData\Local\Temp\NutanixCmdlets\logs
.LINK
	www.nutanix.com
.EXAMPLE
    NTNX-Map-Object -mappingType "NETWORK" -sourceData $vmNetworks -targetData $availNetworks -Filter name,VlanId
#> 
	Param(
		[parameter(Mandatory=$true)][array]$mappingType,
		
		[parameter(Mandatory=$true)][array]$sourceData,
		
		[parameter(Mandatory=$true)][array]$targetData,
		
		[parameter(Mandatory=$false)]$filter
	)
	
	begin {
		
		# Get source
		if ($sourceData.length -gt 1) {
			$sourceObj = NTNX-Build-Menu -Title "Please select a source:" -Data $sourceData -Filter $filter
			
			if ($sourceObj -eq "DONE") {
				Write-Host "Mapping cancelled or completed by user!"
				break
			}
		} else {
			$sourceObj = $sourceData
		}
				
		# Get target
		if ($targetData.length -gt 1) {
			$targetObj = NTNX-Build-Menu -Title "Please select a target:" -Data $targetData -Filter $filter
			
			if ($targetObj -eq "DONE") {
				Write-Host "Mapping cancelled or completed by user!"
				break
			}	
		} else {
			$targetObj = $targetData
		}
		
		Write-Host "Created the mapping of $sourceObj to $targetObj"
	}
	process {
		$mapping = New-Object PSCustomObject -Property @{
			mappingType = $mappingType
			sourceObj = $sourceObj
			targetObj = $targetObj
		}
	}
	end {
		return $mapping
	}
}

#endregion

#region Core Functions
############################################################
##
## Function: NTNX-Install-MSI
## Author: Steven Poitras
## Description: Automate bulk MSI installation
## Language: PowerShell
##
############################################################
function NTNX-Install-MSI {
<#
.NAME
	NTNX-Install-MSI
.SYNOPSIS
	Installs Nutanix package to Windows hosts
.DESCRIPTION
	Installs Nutanix package to Windows hosts
.NOTES
	Authors:  thedude@nutanix.com
	
	Logs: C:\Users\<USERNAME>\AppData\Local\Temp\NutanixCmdlets\logs
.LINK
	www.nutanix.com
.EXAMPLE
    NTNX-Install-MSI -installer "Nutanix-VirtIO-1.0.0.msi" `
		-cert "NutanixSoftware.cer" -localPath "C:\" `
		-computers $compArray -credential $(Get-Credential)
		
	NTNX-Install-MSI -installer "Nutanix-VirtIO-1.0.0.msi" `
		-cert "NutanixSoftware.cer" -localPath "C:\" `
		-computers "99.99.99.99"
#> 
	Param(
		[parameter(mandatory=$true)]$installer,
		
		[parameter(mandatory=$true)]$cert,
		
		[parameter(mandatory=$true)][AllowNull()]$localPath,
		
		[parameter(mandatory=$true)][Array]$computers,
		
		[parameter(mandatory=$false)][AllowNull()]$credential,
		
		[parameter(mandatory=$false)][Switch]$force
	)

	begin{
		# Pre-req message
		Write-host "NOTE: the following pre-requisites MUST be performed / valid before script execution:"
		Write-Host "	+ Nutanix installer must be downloaded and installed locally"
		Write-Host "	+ Export Nutanix Certificate in Trusted Publishers / Certificates"
		Write-Host "	+ Both should be located in c:\ if localPath not specified"
		
		if ($force.IsPresent) {
			Write-Host "Force flag specified, continuing..."
		} else {
			$input = Read-Host "Do you want to continue? [Y/N]"
				
			if ($input -ne 'y') {
				break
			}
		}

		if ($(Get-ExecutionPolicy) -ne 'Unrestricted') {
			Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false
		}
		
		Write-Host "Adding hosts to WinRM TrustedHosts..."
		winrm s winrm/config/client '@{TrustedHosts="*"}'
		
		$failedInstall = @()
		
		# Import modules and add snappins
		#Import-Module DnsClient

		# Installer and cert filenames
		if ([string]::IsNullOrEmpty($localPath)) {
			# Assume location is c:\
			$localPath = 'c:\'
		}
		
		# Path for ADMIN share used in transfer
		$adminShare = "C:\Windows\"
		
		# Format paths
		$localInstaller = $(Join-Path $localPath $installer)
		$localCert = $(Join-Path $localPath $cert)
		$remoteInstaller = $(Join-Path $adminShare $installer)
		$remoteCert = $(Join-Path $adminShare $cert)
		
		# Make sure files exist
		if (!(Test-Path -Path $localInstaller) -or !(Test-Path -Path $localCert)) {
			Write-Host "Warning one of more input files missing, exiting..."
			break
		}
		
		# Credential for remote PS connection
		if (!$credential) {
			$credential = Get-Credential -Message "Please enter domain admin credentials `
				Example: <SPLAB\superstevepo/*******>"
		}
		
		# Make sure drive doesn't exist
		Remove-PSDrive -Name P -ErrorAction SilentlyContinue
	
	}
	process {
		# For each computer copy file and install drivers
		$computers | %	{
			$vmConn = $null
			$l_vm = $_
			
			$vmType = $_.GetType().Name
			
			Write-Host "Object type is $vmType"
			
			# Determine passed object type
			Switch ($vmType) {
				# Nutanix object
				"VMDTO"	{$vmIP = $l_vm.ipAddresses}
				
				# VMware object
				"VirtualMachineImpl" {$vmIP = $l_vm.Guest.IPaddress | where {$_ -notmatch ":"}}
				
				# Hyper-V object
				"VirtualMachine" {$vmIP = $l_vm.NetworkAdapters.IPAddresses | where {$_ -notmatch ":"}}
				
				# Array object
				"Object[]" {$vmIP = $l_vm}
				
				# String
				"String" {$vmIP = $l_vm}
			}
			
			Write-Host "Found IPs: $vmIP"
			
			# For each IP try to connect until one is successful
			$vmIP | %{
				if(Test-Connection -ComputerName $_ -Count 3 -Quiet) {
					# Connection
					Write-Host "Successful connection on IP: $_"
					
					$vmConn = $_
					
					return
				} else {
					Write-Host "Unable to connect on IP: $_"
				}
			}
			
			# Make sure connection exists
			if ($vmConn -eq $null) {
				# No connection
				Write-Host "Unable to connect to VM, skipping..."
				return
			}
		
			# Create a new PS Drive
			New-PSDrive -Name P -PSProvider FileSystem -Root \\$vmConn\ADMIN$ `
				-Credential $credential | Out-Null
			
			# Copy virtio installer
			Write-Host "Copying installer to host..."
			Copy-Item  $localInstaller P:\$installer | Out-Null
			
			# Copy Nutanix cert
			Write-Host "Copying Nutanix Certificate to host..."
			Copy-Item $localCert P:\$cert | Out-Null
			
			# Create PS Session
			$sessionObj = New-PSSession -ComputerName $vmConn -Credential $credential
			
			# Install certificate for signing
			Write-Host "Installing certificate on host..."
			$certResponse = Invoke-Command -session $sessionObj -ScriptBlock {
				certutil -addstore "TrustedPublisher" $args[0]
			} -Args $remoteCert
			
			# Install driver silently
			Write-Host "Installing package on host..."
			$installResponse = Invoke-Command -session $sessionObj -ScriptBlock {
				$status = Start-Process -FilePath "msiexec.exe"  -ArgumentList `
					$args[0] -Wait -PassThru 
				
				return $status
			} -Args "/i $remoteInstaller /qn"
			
			# Check and return install status
			if ($installResponse.ExitCode -eq 0) {
				Write-Host "Installation of Nutanix package succeeded!"
			} else {
				Write-Host "Installation of Nutanix package failed..."
				$failedInstall += $l_vm
			}
			
			# Cleanup PS drive
			Remove-PSDrive -Name P
		
			# Cleanup session
			Disconnect-PSSession -Session $sessionObj -ErrorAction SilentlyContinue `
				| Remove-PSSession 

		}
	
	}
	end {
		# Return objects where install failed
		return $failedInstall
	}
}

############################################################
##
## Function: NTNX-Import-VM
## Author: Steven Poitras
## Description: Import VMs
## Language: PowerShell
##
############################################################
function NTNX-Import-VM {
<#
.NAME
	NTNX-Import-VM
.SYNOPSIS
	Automate VM migration and conversion from vSphere to Acropolis Hypervisor
.DESCRIPTION
	Automate VM migration and conversion from vSphere to Acropolis Hypervisor
.NOTES
	Authors:  thedude@nutanix.com
	
	Logs: C:\Users\<USERNAME>\AppData\Local\Temp\NutanixCmdlets\logs
	
	This should be run from a domain joined computer and have administrative 
	right to install and configure services on the desired hosts
.LINK
	www.nutanix.com
.EXAMPLE
	NTNX-Import-VM
#> 
	param (

	)
	
	begin {
		# Pre-req message
		Write-host "NOTE: the following pre-requisites MUST be performed / valid before script execution:"
		Write-Host "	+ Nutanix Powershell CMDlets must be installed locally"
		Write-Host "	+ VMware PowerCLI must be installed locally"
		Write-Host "	+ Nutanix VirtIO MSI must be downloaded and installed locally"
		Write-Host "	+ Export Nutanix Certificate in Trusted Publishers / Certificates"
		Write-Host "	+ Certificate and VirtIO MSI should be located in c:\ if localPath not specified"
		
		if ($force.IsPresent) {
			Write-Host "Force flag specified, continuing..."
		} else {
			$input = Read-Host "Do you want to continue? [Y/N]"
				
			if ($input -ne 'y') {
				break
			}
		}
		
		if ($(Get-ExecutionPolicy) -ne 'Unrestricted') {
			Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force -Confirm:$false
		}
	
		# Import modules and add snappins
		if (!(Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
			Write-Host "Nutanix snappin not loaded, trying to load..."
			Add-PSSnapin NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue
		}
		
		if (!(Get-PSSnapin -Name NutanixCmdletsPSSnapin -ErrorAction SilentlyContinue)) {
			Write-Host "Nutanix snappin not installed, exiting..."
			break
		}
		
		# Set defaults and initialize objects
		$ntnxConn = @()		# Array for Nutanix connection objects
		$hypConn = @()		# Array for hypervisor manager connection objects
		$moveTasks = @()	# Array for move task objects
		$netMapping = @()	# Array for network mapping
		$acropVM = @()		# Array for Acropolis VM objects
		$sleepSecs = 300	# Default sleep time
				
		##########################
		##	Get connections
		##########################
		
		Disconnect-NutanixCluster -NutanixClusters $(Get-NutanixCluster) -ErrorAction SilentlyContinue
		
		# Gather Nutanix addresses
		$nxIPs = ((Read-Host "Please enter the Nutanix server addresses seperated by commas (if multiple)") -split ",").Trim(" ")
		
		if (!$nxIPs) {
			Write-Host "No Nutnaix server entered or cancel pressed, exiting..."
			break
		}
		
		# For each Nutanix cluster try to connect
		$nxIPs | %{
			# Connect to Nutanix servers
			$l_ntnxConn = NTNX-Connect-NTNX -ip $_ -credential `
				$(Get-Credential -Message "Please enter the Nutanix Prism credentials for $($_) <admin/*******>")
			
			# Add connection to connection array
			$ntnxConn += $l_ntnxConn
		}
		
		# Gather hypervisor management server addresses
		$hypIPs = ((Read-Host "Please enter the management server addresses seperated by commas (if multiple)") -split ",").Trim(" ")
		
		if (!$hypIPs) {
			Write-Host "No management server entered or cancel pressed, exiting..."
			break
		}
		
		# For each vCenter try to connect
		$hypIPs | %{
			# Connect to management servers
			$l_hypConn = NTNX-Connect-HYP -IP $_ -Type $hypType -Credential `
				$(Get-Credential -Message "Please enter the Management server admin credentials <SPLAB\superstevepo/*******>")
			
			# Add connection to connection array
			$hypConn += $l_hypConn
		}
		
		##########################
		##	Get inputs
		##########################
		
		$targetCtr = NTNX-Build-Menu -Title "Please select a container to use: " `
			-Data $(Get-NTNXContainer) -filter name -endObj "New"
		
		# If new container is selected prompt for name
		if ($targetCtr -eq "New") {
			# Get name for container
			$ctrName = Read-Host "Please enter a container name"
		
			# Create Container
			$ctrCreateResult = New-NTNXContainer -Name $ctrName `
				-StoragePoolId $(Get-NTNXStoragePool).id -FingerPrintOnWrite ON
			
			if ($ctrCreateResult -eq "Success!") {
				# Container creation succeeded
				$targetCtr = Get-NTNXContainer | where {$_.name -match $ctrName}
			} else {
				# Container creation failed, exit
				Write-Host "Container creation failed, exiting..."
				break
			}
			
		}
		
		# Get source VMware cluster
		$availCluster = Get-Cluster
		
		$sourceCluster = NTNX-Build-Menu -Title "Please select a source cluster: " `
			-Data $availCluster -filter Name
		
		# Get host objects once
		$vmHosts = $sourceCluster | Get-VMHost
		
		# Get host ips for whitelist
		$sourceHostIP = ($vmHosts | Get-VMHostNetworkAdapter `
			| where {$_.IP -match "."} | select -ExpandProperty IP -Unique | `
				ForEach-Object {$_ + "/255.255.255.255"})
		
		# Configure whitelist
		Set-NTNXContainer -Id $targetCtr.id -NfsWhitelist $sourceHostIP

	}
	
	process {				
		# Check if datastore exists, and if not, mount it
		$vmHosts | %{
			# Check if container exists
			if ($_ | Get-Datastore -Name $targetCtr.name -ErrorAction SilentlyContinue) {
				# Already mounted
				Write-Host "Datastore already exists, continuing..."
			} else {
				Write-Host "Datastore doesn't exist, mounting on host $_"
				
				New-Datastore -nfs -Name $targetCtr.name -VMHost $_ `
					-NfsHost $ntnxConn.IP -Path ("/" + $targetCtr.name) -WarningAction SilentlyContinue
			}
			
		}
					
		# Get datastore object
		$targetDatastore = Get-Datastore -Name $targetCtr.name
		
		# Get VMs to migrate from vSphere
		[System.Collections.ArrayList]$aggVM = @($sourceCluster | Get-VM)
		
		# Create array to store selected VMs
		[System.Collections.ArrayList]$selVM = @()
		
		# Select VMs to migrate
		while ($aggVM.length -gt 0 -and $selVM.count -le 0) {
			$l_selVM = NTNX-Build-Menu -Title "Please select a VM to migrate:" `
				-Data $aggVM -Filter Name,PowerState -EndObj "All","DONE"
			
			if ($l_selVM -eq "DONE") {
				break
			} elseif ($l_selVM -eq "ALL") {
				$selVM = $aggVM
				break
			}
			
			$selVM += $l_selVM
			$aggVM.Remove($l_selVM)
		}
		
		# Get source port groups
		$sourceNet = $selVM | Get-VirtualPortGroup
		
		# Get existing target networks
		$targetNet = Get-NTNXNetwork
		
		$sourceNet | %{
			$l_sourceNet = $_
			
			# Check if network exists
			if ($targetNet.vlanId -contains $l_sourceNet.VLanId) {
				Write-Host "Found network $l_sourceNet on target"
			} else {
				# Network not found, create...
				Write-Host "Network $l_sourceNet not found, creating on target..."
				New-NTNXNetwork -VlanId $l_sourceNet.VLanId #-Name $l_sourceNet.Name
			}
			
			#Get network object
			$l_foundNet = $(Get-NTNXNetwork | where {$_.vlanId -eq $l_sourceNet.VLanId})
			
			$l_netMapping = NTNX-Map-Object -mappingType "NETWORK" `
				-sourceData $l_sourceNet -targetData $l_foundNet -filter vlanId
			
			# Create mapping
			$netMapping += $l_netMapping
		}
		
		if ($sourceNet.Count -gt $netMapping.Count) {
			# Not all networks found or created
			Write-Host "Warning: not all networks found!"
		}
		
		# Get VM view objects
		$vmView = $selVM | Get-View
		
		# Get Windows VMs
		$winVMView = $vmView | where {$_.Config.GuestFullName -match "Microsoft"}
		$winVM = $selVM |? {$winVMView.name -eq $_.name -or $_.Guest.OSFullName -match "Microsoft"}
		
		Write-Host "Found $($winVM.length) Windows VMs!"
		
		if ($winVM) {
			# Start powered-off VMs to install driver
			Write-Host "Starting any powered-off Windows VMs to install driver..."
			
			$vmsToPowerOn = $winVM | where {$_.PowerState -ne "PoweredOn"}

			if ($vmsToPowerOn) {
				# VMs need to be powered on
				$vmsToPowerOn | Start-VM -Confirm:$false | Out-Null
				
				# Wait and allow time to boot
				Write-Host "Sleeping to allow $($vmsToPowerOn.length) VM(s) to boot"
				Start-Sleep $sleepSecs
			
			}
			
			# Get inputs for certificate and installer names
			$localPath = (Read-Host "Please enter the root folder for the certificate and installer [ex. c:\]").Trim(" ")
			
			$installerName = $(Get-ChildItem $localPath | where {$_.Name -like "Nutanix*msi"}).Name
			
			if ($installerName.count -gt 1) {
				Write-Host "More than one installer found, prompting for selection..."
				$installerName = NTNX-Build-Menu -Title "Please select a installer" -Data $installerName
			} elseif ($installerName.count -eq 0) {
				# Not found, prompt for input
				Write-Host "Installer not found, prompting for input..."
				$installerName = (Read-Host "Please enter the name of the Nutanix VirtIO MSI [ex. Nutanix-VirtIO-1.0.0.msi]").Trim(" ")
			} else {
				Write-Host "Found installer in directory!"
			}
			
			$certName = $(Get-ChildItem $localPath | where {$_.Name -like "*.cer"}).Name
			
			if ($certName.count -gt 1) {
				Write-Host "More than one installer found, prompting for selection..."
				$certName = NTNX-Build-Menu -Title "Please select a installer" -Data $certName
			} elseif ($certName.count -eq 0) {
				# Not found, prompt for input
				Write-Host "Installer not found, prompting for input..."
				$certName = (Read-Host "Please enter the name of the Nutanix Certificate [ex. blah.cer]").Trim(" ")
			} else {
				Write-Host "Found certificate in directory!"
			}
			
			# Install VirtIO MSI
			Write-Host "Installing VirtIO on $($winVM.length) Windows VMs..."
			$failedInstall = NTNX-Install-MSI -installer $installerName `
				-cert $certName -localPath $localPath -computers $winVM `
				-credential $(Get-Credential -Message "Please enter the Windows OS admin credentials <SPLAB\superstevepo/*******>") `
				-Force
				
			# Remove failed VirtIO install VMs 
			$failedInstall | %{
				Write-Host "Installation of VirtIO failed on VM: $($_.Name), not migrating..."
				$selVM.Remove($_)
			}
		}
		
		# Storage vMotion VMs and create template VMs
		$selVM | %{	
			# Storage vMotion VMs over to container
			Write-Host "Migrating $_..."
			$moveTasks += Move-VM -VM $_ -Datastore $targetDatastore `
				-Confirm:$false -RunAsync
			
			if ($(Get-NTNXVM -SearchString $_.Name).length -gt 0) {
				Write-Host "Warning: VM with name $_ already exists, adding postfix..."
				$l_vmName = $_.Name + "-IMPORT-" + $(Get-Date -Format MMddyyyy-Hs)
				Write-Host "VM name is $l_vmName"
			} else {
				$l_vmName = $_.Name
			}
			
			# For each VM create object and create in AHV
			Write-Host "Creating Acropolis VM object for VM: $l_vmName"
			$l_VM = New-NTNXVirtualMachine -Name $l_vmName -NumVcpus $_.NumCpu `
				-MemoryMb $_.MemoryMB # -HaPriority $vmHA
			
			$x = 1
			
			# Get Acropolis VM Object
			while ($l_acropVM -eq $null -or $x -le 3) {
				$l_acropVM = Get-NTNXVM -SearchString $l_vmName
				
				$x += 1
			}
			
			if (!$l_acropVM) {
				Write-Host "Warning could find Acropolis VM!"
				return
				
			}
			
			$vmNics = $_ | Get-NetworkAdapter
			
			# Create VM Nic
			$vmNics | %{
				$l_nic = $_
				
				# Get mapping and target network
				$l_targetNet = $($netMapping | where {$_.sourceObj.Name -match $l_nic.NetworkName}).targetObj
				
				# Add NIC and set uuid
				$nicSpec = New-NTNXObject -Name VMNicSpecDTO
				$nicSpec.networkuuid = $l_targetNet.uuid
				
				# Add NIC using spec
				Write-Host "Adding Nic with VLAN $($l_targetNet.vlanId) to $($l_acropVM.vmName)"
				Add-NTNXVMNIC -Vmid $l_acropVM.vmid -SpecList $nicSpec
			
			}
			
			# Add VM obj to array
			$acropVM += $l_acropVM
				
			# Clear local var
			$l_AcropVM = $null
		
		}
		
		# Get task status
		$activeTask = Get-Task -Id $moveTasks.id -ErrorAction SilentlyContinue
		
		# Clear screen
		Clear
		
		# Wait while disks are moved
		while (($activeTask | where {$_.State -eq "Running"}).count -gt 0) {
			
			# Update tasks and keep sessions alive
			$activeTask = Get-Task -Id $moveTasks.id -ErrorAction SilentlyContinue
			$runningTask = $activeTask | where {$_.State -eq "Running"}
			$completedTask = $activeTask | where {$_.State -eq "Success"}
			$errorTask = $activeTask | where {$_.State -eq "Error"}
			
			# Keep Nutanix Session alive
			Get-NTNXStoragePool | Out-Null
			
			$percentComplete = $($activeTask.PercentComplete | Measure-Object -Average).Average
			
			# Update status
			Write-Progress -Activity "Migrating VMs to Nutanix Storage..." `
				-PercentComplete  $percentComplete `
				-Status "Percent Complete: $percentComplete % - Tasks: $($completedTask.count) Completed, $($runningTask.count) Running, $($errorTask.count) Error"
			
			# Sleep
			Start-Sleep 30
		}
		
		# Power down VMs
		Write-Host "Powering down selected VMs..."
		$selVM | Stop-VM -Confirm:$false -RunAsync -ErrorAction SilentlyContinue
		
		# Attach disks to each VM
		$selVM | %{
			$l_currVM = $_
			$l_acropVM = $acropVM | where {$_.vmName -match $l_currVM.Name}
			
			if (!$l_acropVM) {
				Write-Host "Error: VM not found! Skipping..."
				return
			}
			
			# Create array for objects
			#$l_diskArray = @()
			
			# Add each disk to VM
			$l_currVM.HardDisks | %{
				$l_currDisk = $_
				$l_diskIndex = $l_currDisk.ExtensionData.UnitNumber
				
				# Get source filename for matching
				$l_currFile = $l_currDisk.Filename.split(' ')
				$ctr = $l_currFile[0].Trim("[","]"," ")
				
				$filePath = $l_currFile[1].Split('.')
				
				# Cormatted String
				$formattedPath = '/' + $ctr + '/' + $filePath[0] + '-flat.' + $filePath[1] 
				
				$diskCloneSpec = New-NTNXObject -Name VMDiskSpecCloneDTO
				$diskCloneSpec.imagePath = $formattedPath
				
				$vmDisk = New-NTNXObject -Name VMDiskDTO
				$vmDisk.vmDiskClone = $diskCloneSpec
				
				Write-Host "Adding Disk: $formattedPath to VM: $($l_acropVM.vmName)..."
				Add-NTNXVMDisk -Vmid $l_acropVM.vmid -Disks $vmDisk
			
				<#
				
				#$l_diskArray += $vmDisk
				
				$diskUpdateSpec = New-NTNXObject -Name VMDiskUpdateSpecDTO
				$diskUpdateSpec.vmDiskClone = $diskCloneSpec
				
				Set-NTNXVMDisk -Vmid $l_acropVM.vmid -UpdateSpec $diskUpdateSpec -Diskaddress $("scsi-" + $l_diskIndex)
				
				#>
				
			}
			
			# Add list of disks
			#Add-NTNXVMDisk -Vmid $l_acropVM.vmid -Disks $l_diskArray
			
			# Power-On VM
			Write-Host "Powering on VM: $($l_acropVM.vmName)..."
			Set-NTNXVMPowerOn -Vmid $l_acropVM.vmid
			
		}
	
	}
	
	end {
		Write-Host "Migration failed for the folling VMs: $($failedInstall.Name)"
	
		# Remove datastore from source hosts
		Write-Host "Removing datastore from source hosts..."
		$sourceCluster | Get-VMHost | Remove-Datastore `
			-Datastore $targetDatastore -Confirm:$false -RunAsync
	
		# Cleanup sessions and disconnect
		Write-Host "Clearing up sessions..."
		Disconnect-NutanixCluster -NutanixClusters $(Get-NutanixCluster)
		
	}
}

#endregion

# Execute funcation
NTNX-Import-VM