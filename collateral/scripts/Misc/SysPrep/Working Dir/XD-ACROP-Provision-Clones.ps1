############################################################
##
## Function: NTNX-Build-Menu
## Author: Steven Poitras
## Description: Helper function to build menu
## Language: PowerShell
##
############################################################
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
    [parameter(Mandatory=$false)][string]$EndObj
)
	$Increment = 0
	$filteredData = $Data | select $filter
	write-host ""
	write-host $Title
	$filteredData | %{
		$Increment +=1
		write-host "$Increment." $_
	}
  
	if ([string]::IsNullOrEmpty($EndObj)) {
  		$EndObj = "DONE"
	}
	
	$Increment +=1
  	write-host "$Increment. " $EndObj
	
	$index = (read-host "Please select an option [Example: 1]")-1
  
	# Selection is valid
	if ($Data[$index]) {
		$selection = $Data[$index]
		write-host "You selected: $($selection | select $filter) at index $index"
	} else { # Assuming last index was selected
		$selection = $EndObj
		Write-Host 	"You selected $EndObj"
	}

	return $selection
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
			$IP = Read-Host "Please enter a IP or hostname for the Nutanix cluter: "
		}
		
		# If not connected, try connecting
		if ($(Get-NutanixCluster -Servers $IP -ErrorAction SilentlyContinue).IsConnected -ne "True") {  # Not connected
			Write-Host "Connecting to Nutanix cluster ${IP} as $($credential.UserName.Trim("\")) ..."
			$connObj = Connect-NutanixCluster -Server $IP -UserName $($credential.UserName.Trim("\")) `
				-Password $(([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)))) -AcceptInvalidSSLCerts
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

############################################################
##
## Function: NTNX-Create-VM
## Author: Steven Poitras
## Description: Create Acropolis VM Clones
## Language: PowerShell
##
############################################################
function NTNX-Create-VM {
<#
.NAME
	NTNX-Create-VM
.SYNOPSIS
	Create Acropolis VM Clones
.DESCRIPTION
	Create Acropolis VM Clones
.NOTES
	Authors:  thedude@nutanix.com
	
	Logs: C:\Users\<USERNAME>\AppData\Local\Temp\NutanixCmdlets\logs
.LINK
	www.nutanix.com
.EXAMPLE
    NTNX-Create-VM -image <VM IMAGE> -prefix "test-###" -startInt 50 -quantity 500
#> 
	Param(
	    [parameter(mandatory=$false)][AllowNull()]$image,
		
		[parameter(mandatory=$false)][AllowNull()]$prefix,
		
		[parameter(mandatory=$false)][AllowNull()]$startInt,
		
		[parameter(mandatory=$false)][AllowNull()]$quantity
	)

	begin{
		# Connect to Nutanix cluster
		NTNX-Connect-NTNX -ip $targetCluster `
			-credential $(Get-Credential `
			-Message "Please enter the Nutanix Prism credentials <admin/*******>")
			
		##########################
		##	Get inputs
		##########################
		
		$vms = Get-NTNXVM
		
		# Get base image if not passed
		if (!$image) {
			# No image passed, prompt for input
			$image = NTNX-Build-Menu -Title "Please select a Base image:" -Data $vms -Filter vmName
		} else {
			# Make sure VM object exists
			if ($vms.vmName -notcontains $image.vmName) {
				# Image not found, prompt for input
				Write-Host "Image not found, prompting for input..."
				$image = NTNX-Build-Menu -Title "Please select a Base image:" -Data $vms -Filter vmName
			} else {
				Write-Host "Image found!"
			}
		}
		
		# Get VM prefix if not passed
		if ([string]::IsNullOrEmpty($prefix)) {
			$prefix = Read-Host "Please enter a name prefix and int structure [e.g. myClones-###]: "
		}
		
		# Get starting int if not passed
		if ([string]::IsNullOrEmpty($startInt)) {
			$startInt = Read-Host "Please enter a starting int [e.g. 1]: "
		}
		
		# If ints aren't formatted
		if ($prefix -notmatch '#') {
			$length = 3
		} else {
			$length = [regex]::matches($prefix,"#").count
			
			# Remove # from prefix
			$prefix = $prefix.Trim('#')
		}
		
		# Get VM quantity if not passed
		if ([string]::IsNullOrEmpty($quantity)) {
			$quantity = Read-Host "Please enter the desired quantity of VMs to be provision: "
		}
		
	}
	process {
		1..$quantity | %{
			
			$l_formattedInt = "{0:D$length}" -f $($_+$startInt-1)
			
			$l_formattedName = "$prefix$l_formattedInt"
			
			Write-Host "Creating clone $l_formattedName"
			
			# Create clone
			<#########
			
			<--STUB-->
			
			#Clone-NTNXVirtualMachine -
			
			#########>
		}
	}
	end {
		Write-Host "Configuration complete, clearing up sessions..."
	
		# Cleanup sessions and disconnect
		Disconnect-NutanixCluster -NutanixClusters $(Get-NutanixCluster)
	}
}

<#
Example Usage:
NTNX-Create-VM

NTNX-Create-VM -image <VM IMAGE> -prefix "test-###" -startInt 50 -quantity 500
#>