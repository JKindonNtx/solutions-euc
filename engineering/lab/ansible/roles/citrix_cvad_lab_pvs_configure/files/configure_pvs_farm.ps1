#==========================================================================
#
# Configure Citrix Provisioning Server
#
# AUTHOR: Dennis Span (https://dennisspan.com)
# DATE  : 06.05.2017
#
# COMMENT:
# This script has been prepared for Windows Server 2008 R2, 2012 R2 and 2016
# and Citrix Provisioning Server 7.13 and higher (will probably work for PVS 7.7 and higher).
#
# This script creates or joins the Provisioning Server farm, configures the farm and the local host.
#
#==========================================================================

# Get the script parameters if there are any
param
(
    # The only parameter which is really required is 'Uninstall'
    # If no parameters are present or if the parameter is not
    # 'uninstall', an installation process is triggered
    [string]$Installationtype
)

# define Error handling
# note: do not change these values
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# FUNCTION DS_WriteLog
#==========================================================================
Function DS_WriteLog {
    <#
        .SYNOPSIS
        Write text to this script's log file
        .DESCRIPTION
        Write text to this script's log file
        .PARAMETER InformationType
        This parameter contains the information type prefix. Possible prefixes and information types are:
            I = Information
            S = Success
            W = Warning
            E = Error
            - = No status
        .PARAMETER Text
        This parameter contains the text (the line) you want to write to the log file. If text in the parameter is omitted, an empty line is written.
        .PARAMETER LogFile
        This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
        .EXAMPLE
        DS_WriteLog -InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing information to the log file
        .Example
        DS_WriteLog -InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing error information to the log file
        .Example
        DS_WriteLog -InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
        Writes an empty line to the log file
    #>
    [CmdletBinding()]
	Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$InformationType,
        [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
        [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
    )

	$DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
	
    if ( $Text -eq "" ) {
        Add-Content $LogFile -value ("") # Write an empty line
    } Else {
	    Add-Content $LogFile -value ($DateTime + " " + $InformationType + " - " + $Text)
    }
}
#==========================================================================

# FUNCTION DS_CreateRegistryKey
#==========================================================================
Function DS_CreateRegistryKey {
    <#
        .SYNOPSIS
        Create a registry key
        .DESCRIPTION
        Create a registry key
        .PARAMETER RegKeyPath
        This parameter contains the registry path, for example 'hklm:\Software\MyApp'
        .EXAMPLE
        DS_CreateRegistryKey -RegKeyPath "hklm:\Software\MyApp"
        Creates a new registry key called 'hklm:\Software\MyApp'
    #>
    [CmdletBinding()]
	Param( 
		[Parameter(Mandatory=$true, Position = 0)][String]$RegKeyPath
	)

    DS_WriteLog "I" "Create registry key $RegKeyPath" $LogFile
    if ( Test-Path $RegKeyPath ) {
        DS_WriteLog "I" "The registry key $RegKeyPath already exists. Nothing to do." $LogFile
    } else {
        try {
            New-Item -Path $RegkeyPath -Force | Out-Null
		    DS_WriteLog "S" "The registry key $RegKeyPath was created successfully" $LogFile
	    }
	    catch{
            DS_WriteLog "E" "An error occurred trying to create the registry key $RegKeyPath (exit code: $($Error[0])!" $LogFile
            DS_WriteLog "I" "Note: define the registry path as follows: hklm:\Software\MyApp" $LogFile
            Exit 1
	    }
    }
}
#==========================================================================

# FUNCTION DS_SetRegistryValue
#==========================================================================
Function DS_SetRegistryValue {
    <#
        .SYNOPSIS
        Set a registry value
        .DESCRIPTION
        Set a registry value
        .PARAMETER RegKeyPath
        This parameter contains the registry path, for example 'hklm:\Software\MyApp'
        .PARAMETER RegValueName
        This parameter contains the name of the new registry value, for example 'MyValue'
        .PARAMETER RegValue
        This parameter contains the value of the new registry entry, for example '1'
        .PARAMETER Type
        This parameter contains the type (possible options are: String, Binary, DWORD, QWORD, MultiString, ExpandString)
        .EXAMPLE
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyStringValue" -RegValue "Enabled" -Type "String"
        Creates a new string value called 'MyStringValue' with the value of 'Enabled'
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyBinaryValue" -RegValue "01" -Type "Binary"
        Creates a new binary value called 'MyBinaryValue' with the value of '01'
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyDWORDValue" -RegValue "1" -Type "DWORD"
        Creates a new DWORD value called 'MyDWORDValue' with the value of 1
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyQWORDValue" -RegValue "1" -Type "QWORD"
        Creates a new QWORD value called 'MyQWORDValue' with the value of 1
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyMultiStringValue" -RegValue "Value1,Value2,Value3" -Type "MultiString"
        Creates a new multistring value called 'MyMultiStringValue' with the value of 'Value1 Value2 Value3'
        .Example
        DS_SetRegistryValue -RegKeyPath "hklm:\Software\MyApp" -RegValueName "MyExpandStringValue" -RegValue "MyValue" -Type "ExpandString"
        Creates a new expandstring value called 'MyExpandStringValue' with the value of 'MyValue'
    #>
    [CmdletBinding()]
	Param( 
		[Parameter(Mandatory=$true, Position = 0)][String]$RegKeyPath,
		[Parameter(Mandatory=$true, Position = 1)][String]$RegValueName,
		[Parameter(Mandatory=$false, Position = 2)][String[]]$RegValue = "",
		[Parameter(Mandatory=$true, Position = 3)][String]$Type
	)

    DS_WriteLog "I" "Set registry value $RegValueName = $RegValue (type $Type) in $RegKeyPath" $LogFile

    # Create the registry key in case it does not exist
    if ( !( Test-Path $RegKeyPath ) ) {
        DS_CreateRegistryKey $RegKeyPath
    }
    
    # Create the registry value
    try {
        if ( ( "String", "ExpandString", "DWord", "QWord" ) -contains $Type ) {
		    New-ItemProperty -Path $RegKeyPath -Name $RegValueName -Value $RegValue[0] -PropertyType $Type -Force | Out-Null
	    } else {
		    New-ItemProperty -Path $RegKeyPath -Name $RegValueName -Value $RegValue -PropertyType $Type -Force | Out-Null
	    }
        DS_WriteLog "S" "The registry value $RegValueName = $RegValue (type $Type) in $RegKeyPath was set successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to set the registry value $RegValueName = $RegValue (type $Type) in $RegKeyPath" $LogFile
        DS_WriteLog "I" "Note: define the registry path as follows: hklm:\Software\MyApp" $LogFile
        Exit 1
    }
}
#==========================================================================

# FUNCTION DS_CreateDirectory
#==========================================================================
Function DS_CreateDirectory {
    <#
        .SYNOPSIS
        Create a new directory
        .DESCRIPTION
        Create a new directory
        .PARAMETER Directory
        This parameter contains the name of the new directory including the full path (for example C:\Temp\MyNewFolder).
        .EXAMPLE
        DS_CreateDirectory -Directory "C:\Temp\MyNewFolder"
        Creates the new directory "C:\Temp\MyNewFolder"
    #>
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true, Position = 0)][String]$Directory
	)

    DS_WriteLog "I" "Create the directory $Directory" $LogFile
    if ( Test-Path $Directory ) {
        DS_WriteLog "I" "The directory $Directory already exists. Nothing to do." $LogFile
    } else {
        try {
            New-Item -ItemType Directory -Path $Directory -force | Out-Null
            DS_WriteLog "S" "Successfully created the directory $Directory" $LogFile
        } catch {
            DS_WriteLog "E" "An error occurred trying to create the directory $Directory (exit code: $($Error[0])!" $LogFile
            Exit 1
        }
    }
}
#==========================================================================

# FUNCTION DS_DeleteDirectory
# Description: delete the entire directory
#==========================================================================
Function DS_DeleteDirectory {
    <#
        .SYNOPSIS
        Delete a directory
        .DESCRIPTION
        Delete a directory
        .PARAMETER Directory
        This parameter contains the full path to the directory which needs to be deleted (for example C:\Temp\MyOldFolder).
        .EXAMPLE
        DS_DeleteDirectory -Directory "C:\Temp\MyOldFolder"
        Delete the directory "C:\Temp\MyNewFolder"
    #>
    [CmdletBinding()]
	Param( 
		[Parameter(Mandatory=$true, Position = 0)][String]$Directory
	)

    DS_WriteLog "I" "Delete directory $Directory" $LogFile
    if ( Test-Path $Directory ) {
        try {
            Remove-Item $Directory -force -recurse | Out-Null
            DS_WriteLog "S" "Successfully deleted the directory $Directory" $LogFile
        } catch {
            DS_WriteLog "E" "An error occurred trying to delete the directory $Directory (exit code: $($Error[0])!" $LogFile
            Exit 1
        }
    } else {
       DS_WriteLog "I" "The directory $Directory does not exist. Nothing to do." $LogFile
    }
}
#==========================================================================

# FUNCTION DS_DeleteFile
# Description: delete one specific file
#==========================================================================
Function DS_DeleteFile {
    <#
        .SYNOPSIS
        Delete a file
        .DESCRIPTION
        Delete a file
        .PARAMETER File
        This parameter contains the full path to the file (including the file name and file extension) that needs to be deleted (for example C:\Temp\MyOldFile.txt).
        .EXAMPLE
        DS_DeleteFile -File "C:\Temp\MyOldFile.txt"
        Delete the file "C:\Temp\MyOldFile.txt"
    #>
    [CmdletBinding()]
	Param( 
		[Parameter(Mandatory=$true, Position = 0)][String]$File
	)

    DS_WriteLog "I" "Delete the file $File" $LogFile
    if ( Test-Path $File ) {
        try {
            Remove-Item "$File" | Out-Null
            DS_WriteLog "S" "Successfully deleted the file $File" $LogFile
        } catch {
            DS_WriteLog "E" "An error occurred trying to delete the file $File (exit code: $($Error[0])!" $LogFile
            Exit 1
        }
    } else {
       DS_WriteLog "I" "The file $File does not exist. Nothing to do." $LogFile
    }
}
#==========================================================================

# FUNCTION DS_CreateFirewallRule
#==========================================================================
Function DS_CreateFirewallRule {
 <#
        .SYNOPSIS
        Create a local firewall rule on the local server
        .DESCRIPTION
        Create a local firewall rule on the local server. On Windows Server 2008 (R2) the NetSh command
        is used. For operating systems from Windows Server 2012 and later, the PowerShell cmdlet 
        'New-NetFirewallRule' is used. The firewall profile is automatically set to 'any'.
        .PARAMETER Name
        This parameter contains the name of the firewall rule (the name must be unique and cannot be 'All').
        The parameter name is used for both the 'name' as well as the 'displayname'.
        .PARAMETER Description
        This parameter contains the description of the firewall rule. The description can be an empty string.
        .PARAMETER Ports
        This parameter contains the port or ports which should be allowed or denied. Possible notations are:
            Example 1: 80,81,82,90,93
            Example 2: 80-82,90,93
        .PARAMETER Protocol
        This parameter contains the name of the protocol. The most used options are 'TCP' or 'UDP', but more options are available.
        See the article https://technet.microsoft.com/en-us/library/dd734783(v=ws.10).aspx#BKMK_3_add
        .PARAMETER Direction
        This parameter contains the direction. Possible options are 'Inbound' or 'Outbound'.
        .PARAMETER Action
        This parameter contains the action. Possible options are 'Allow' or 'Block'.
        .EXAMPLE
        DS_CreateFirewallRule -Name "Citrix example firewall rules" -Description "Examples firewall rules for Citrix" -Ports "80-82,99" -Protocol "UDP" -Direction "Inbound" -Action "Allow"
        Create an inbound firewall rule for the UDP protocol
    #>
    [CmdletBinding()]
	Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$Name,
        [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Description,
        [Parameter(Mandatory=$true, Position = 2)][String]$Ports,
        [Parameter(Mandatory=$true, Position = 3)][String]$Protocol,
        [Parameter(Mandatory=$true, Position = 4)][ValidateSet("Inbound","Outbound",IgnoreCase = $True)][String]$Direction,
        [Parameter(Mandatory=$true, Position = 5)][ValidateSet("Allow","Block",IgnoreCase = $True)][String]$Action
    )

    DS_WriteLog "I" "Create the firewall rule '$Name' ..." $LogFile
    DS_WriteLog "I" "Parameters:" $LogFile
    DS_WriteLog "I" "-Name: $Name" $LogFile
    DS_WriteLog "I" "-Description: $Description" $LogFile
    DS_WriteLog "I" "-Ports: $Ports" $LogFile
    DS_WriteLog "I" "-Protocol: $Protocol" $LogFile
    DS_WriteLog "I" "-Direction: $Direction" $LogFile
    DS_WriteLog "I" "-Action: $Action" $LogFile

    [string]$WindowsVersion = ( Get-WmiObject -class Win32_OperatingSystem ).Version
    if ( ($WindowsVersion -like "*6.1*") -Or ($WindowsVersion -like "*6.0*") ) {
        # Configure the local firewall using the NetSh command if the operating system is Windows Server 2008 (R2)
        if ( $Direction -eq "Inbound" ) { $DirectionNew = "In" }
        if ( $Direction -eq "Outbound" ) { $DirectionNew = "Out" }
        DS_WriteLog "I" "The operating system is Windows Server 2008 (R2). Use the Netsh command to configure the firewall." $LogFile
        DS_WriteLog "I" "Check if the firewall rule '$Name' already exists." $LogFile
        try {
            [string]$Rule = netsh advfirewall firewall show rule name=$Name
            if ( $Rule.Contains("No rules match") ) {
                DS_WriteLog "I" "The firewall rule '$Name' does not exist." $LogFile
                DS_WriteLog "I" "Create the firewall rule '$Name' ..." $LogFile
                try {
                    netsh advfirewall firewall add rule name=$Name description=$Description localport=$Ports protocol=$Protocol dir=$DirectionNew action=$Action | Out-Null
                    DS_WriteLog "S" "The firewall rule '$Name' was created successfully" $LogFile
                } catch  {
                    DS_WriteLog "E" "An error occurred trying to create the firewall rule '$Name' (error: $($Error[0]))" $LogFile
                    Exit 1
                }
            } else {
                DS_WriteLog "I" "The firewall rule '$Name' already exists. Nothing to do." $LogFile
            }
        } catch {
            DS_WriteLog "E" "An error occurred trying to check the firewall rule '$Name' (error: $($Error[0]))" $LogFile
            Exit 1
        }
    } else {
        # Configure the local firewall using PowerShell if the operating system is Windows Server 2012 or higher
        DS_WriteLog "I" "The operating system is Windows Server 2012 or higher. Use PowerShell to configure the firewall." $LogFile
        DS_WriteLog "I" "Check if the firewall rule '$Name' already exists." $LogFile
        if ( (Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue) -Or (Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue)) {
	        DS_WriteLog "I" "The firewall rule '$Name' already exists. Nothing to do." $LogFile
        } else {
            DS_WriteLog "I" "The firewall rule '$Name' does not exist." $LogFile
            DS_WriteLog "I" "Create the firewall rule '$Name' ..." $LogFile
            [array]$Ports = $Ports.split(',')  # Convert the string value $Ports to an array (required by the PowerShell cmdlet 'New-NetFirewallRule')
            try {
	            New-NetFirewallRule -Name $Name -DisplayName $Name -Description $Description -LocalPort $Ports -Protocol $Protocol -Direction $Direction -Action $Action | Out-Null
                DS_WriteLog "S" "The firewall rule '$Name' was created successfully" $LogFile
            } catch  {
                DS_WriteLog "E" "An error occurred trying to create the firewall rule '$Name' (error: $($Error[0]))" $LogFile
                Exit 1
            }
        }
    }
}
#==========================================================================

# Function DS_CreatePVSAuthGroup
# Note: Create a new Provisioning Server authorization group
#==========================================================================
Function DS_CreatePVSAuthGroup {
    <#
        .SYNOPSIS
        Create a new Provisioning Server authorization group
        .DESCRIPTION
        Create a new Provisioning Server authorization group
        .PARAMETER GroupName
        This parameter contains the name of the Active Directory group which is to be added as an authorization group in the Provisioning Server farm.
        Please be aware that the notation "MyDomain\MyGroup" does not work! The string has be LDAP-like: MyDomain.com/MyOU/MyOU/MyGroup
        .EXAMPLE
        DS_CreatePVSAuthGroup -GroupName "company.com/AdminGroup/CTXFarmAdmins"
        Creates the authorization group 'company.com/AdminGroup/CTXFarmAdmins'
    #>
    [CmdletBinding()]
	Param( 
		[Parameter(Mandatory=$true, Position = 0)][String]$GroupName
	)

    DS_WriteLog "I" "Create a new authorization group" $LogFile
    DS_WriteLog "I" "Group name: $GroupName" $LogFile
    try { 
        Get-PvsAuthGroup -Name $GroupName | Out-Null
        DS_WriteLog "I" "The authorization group '$GroupName' already exists. Nothing to do." $LogFile
    } catch {
        try {
            New-PvsAuthGroup -Name $GroupName | Out-Null
            DS_WriteLog "S" "The authorization group '$GroupName' has been created" $LogFile
        } catch {
            DS_WriteLog "E" "An error occurred trying to create the authorization group '$Groupname' (error: $($Error[0]))" $LogFile
            Exit 1
        }
    }
}
#==========================================================================

# Function DS_GrantPVSAuthGroupAdminRights
# Note: Grant an existing Provisioning Server authorization group farm, site or collection admin rights
#==========================================================================
Function DS_GrantPVSAuthGroupAdminRights {
    <#
        .SYNOPSIS
        Grant an existing Provisioning Server authorization group farm, site or collection admin rights
        .DESCRIPTION
        Grant an existing Provisioning Server authorization group farm, site or collection admin rights
        .PARAMETER GroupName
        This parameter contains the name of the existing Provisioning Server authorization group that is to be granted
        farm, site or collection admin rights. If the parameters 'Sitename' and 'CollectionName' are left empty, the
        authorization group is granted farm admin rights.
        Please be aware that the notation "MyDomain\MyGroup" does not work! The string has be LDAP-like: MyDomain.com/MyOU/MyOU/MyGroup
        .PARAMETER SiteName
        This parameter is optional and contains the site name. If only the site name is specified (without the CollectionName parameter),
        the Provisioning Server authorization group is granted site admin rights.
        .PARAMETER CollectionName
        This parameter is optional and contains the name of the collection. You also have to specify the site name if your want to grant
        collection admin rights.
        .EXAMPLE
        DS_GrantPVSAuthGroupAdminRights -GroupName "company.com/AdminGroup/CTXFarmAdmins"
        Grants the authorization group 'company.com/AdminGroup/CTXFarmAdmins' farm admin rights
        .EXAMPLE
        DS_GrantPVSAuthGroupAdminRights -GroupName "company.com/AdminGroup/CTXSiteAdmins" -SiteName "MySite"
        Grants the authorization group 'company.com/AdminGroup/CTXSiteAdmins' site admin rights
        .EXAMPLE
        DS_GrantPVSAuthGroupAdminRights -GroupName "company.com/AdminGroup/CTXCollectionAdmins" -SiteName "MySite" -CollectionName "MyCollection"
        Grants the authorization group 'company.com/AdminGroup/CTXCollectionAdmins' collection admin rights
    #>
    [CmdletBinding()]
	Param( 
		[Parameter(Mandatory=$true, Position = 0)][String]$GroupName,
		[Parameter(Mandatory=$false)][String]$SiteName,
		[Parameter(Mandatory=$false)][String]$CollectionName
	)   

    # Before attempting to grant admin rights, make sure that the authorization group exists
    try {
        Get-PvsAuthGroup -Name $GroupName | Out-Null
    } catch {
        DS_CreatePVSAuthGroup -GroupName $GroupName
        DS_WriteLog "-" "" $LogFile
    }

    # Grant admin rights to the authorization group
    try {
        if ( ([string]::IsNullOrEmpty($SiteName)) -And ([string]::IsNullOrEmpty($CollectionName)) ) { 
            # Grant farm admin rights when both parameters 'SiteName' and 'CollectionName' are empty
            $result = "farm"
            DS_WriteLog "I" "Grant the authorization group '$GroupName' $result admin rights" $LogFile
            Grant-PvsAuthGroup -authGroupName $GroupName | Out-Null
        } Elseif ( !([string]::IsNullOrEmpty($CollectionName)) ) {
            # Grant collection admin rights when the parameter 'CollectionName' is NOT empty
            $result = "collection"
            DS_WriteLog "I" "Grant the authorization group '$GroupName' $result admin rights" $LogFile
            Grant-PvsAuthGroup -authGroupName $GroupName -SiteName $SiteName -CollectionName $CollectionName | Out-Null
        } Else {
            # Grant site admin rights in all other cases
            $result = "site"
            DS_WriteLog "I" "Grant the authorization group '$GroupName' $result admin rights" $LogFile
            Grant-PvsAuthGroup -authGroupName $GroupName -SiteName $SiteName | Out-Null
        }
        DS_WriteLog "S" "The authorization group '$GroupName' has been granted $result admin rights" $LogFile
    } catch {
        [string]$ErrorText = $Error[0]
        If ( $ErrorText.Contains("duplicate")) {
            DS_WriteLog "I" "The authorization group '$GroupName' already has been granted $result admin rights. Nothing to do." $LogFile
        } else {
            DS_WriteLog "E" "An error occurred trying to grant the authorization group '$GroupName' $result admin rights (error: $($Error[0]))" $LogFile
            Exit 1
        }
    }
}
#==========================================================================

################
# Main section #
################

# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1

# Custom variables [edit]
$BaseLogDir = "C:\Logs"                                         # [edit] add the location of your log directory here
$PackageName = "Citrix Provisioning Server (configure)"         # [edit] enter the display name of the software (e.g. 'Arcobat Reader' or 'Microsoft Office')

# Global variables
$ComputerName = $env:ComputerName
$StartDir = $PSScriptRoot # the directory path of the script currently being executed
if (!($Installationtype -eq "Uninstall")) { $Installationtype = "Install" }
$LogDir = (Join-Path $BaseLogDir $PackageName).Replace(" ","_")
$LogFileName = "$($Installationtype)_$($PackageName).log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

DS_WriteLog "I" "START SCRIPT - $PackageName" $LogFile
DS_WriteLog "-" "" $LogFile

# -----------------------------------
# CUSTOMIZE THE FOLLOWING VARIABLES TO YOUR REQUIREMENTS
# -----------------------------------
$DatabaseServer = $env:pvs_database_server #"MySQLServer.MyDomain.com"
$DatabaseInstance = $env:pvs_database_instance #""   # Leave empty if your SQL server only has one default instance
$DatabaseName = $env:pvs_database_name #"MyPVSDB"
$FarmName = $env:pvs_farm_name #"MyTestFarm"
$SiteName = $env:pvs_site_name #"MyTestSite"
$DefaultCollectionName = $env:pvs_collection_name #"Default"
$DefaultStoreName = $env:pvs_store #"PVSStore"
$DefaultStorePath = $env:pvs_store_path #"$env:SystemDrive\PVSStore"
$LicenseServer = $env:pvs_license_server #"MyCTXLicenseServer.MyDomain.com"
$LicenseServerPort = "27000"
$StreamingIP = "" # If left empty, the script will use the IP address from the first online network adapter
$FirstStreamingPort = "6910"
$LastStreamingPort = "6968"
$BootIP = ""                                         # If left empty, the script will use the IP address from the first online network adapter
$UserName = $env:pvs_username #"MyDomain.com\MyUser"
$Password = $env:pvs_password #"MyPassword"
$FarmAdminGroupName = $env:pvs_admin_group #"MyDomain.com/MyOU/MyOU/MyFarmAdmins"
$SiteAdminGroupName = $env:pvs_admin_group #"MyDomain.com/MyOU/MyOU/MySiteAdmins"        
$CollectionAdminGroupName = $env:pvs_admin_group #"MyDomain.com/MyOU/MyOU/MyCollectionAdmins"
$MaxPasswordAge = "7"
$UNCStoreName = $env:pvs_store #"MyUNCStore"
$UNCStoreDescription = "Default PVS store"
$UNCStorePath = $env:pvs_store_path #"\\MyServer\MyShare"
# -----------------------------------

# Log variables
DS_WriteLog "I" "Your custom variables:" $LogFile
DS_WriteLog "I" "-Database server: $DatabaseServer" $LogFile
DS_WriteLog "I" "-Database instance: $DatabaseInstance" $LogFile
DS_WriteLog "I" "-Database name: $DatabaseName" $LogFile
DS_WriteLog "I" "-Farm name: $FarmName" $LogFile
DS_WriteLog "I" "-Site name: $SiteName" $LogFile
DS_WriteLog "I" "-Default collection name: $DefaultCollectionName" $LogFile
DS_WriteLog "I" "-Default store name: $DefaultStoreName" $LogFile
DS_WriteLog "I" "-Default store path: $DefaultStorePath" $LogFile
DS_WriteLog "I" "-License server: $LicenseServer" $LogFile
DS_WriteLog "I" "-License server port: $LicenseServerPort" $LogFile
DS_WriteLog "I" "-Streaming IP address: $StreamingIP" $LogFile
DS_WriteLog "I" "-First streaming port: $FirstStreamingPort" $LogFile
DS_WriteLog "I" "-Last streaming port: $LastStreamingPort" $LogFile
DS_WriteLog "I" "-Boot IP address: $BootIP" $LogFile
DS_WriteLog "I" "-User name: $UserName" $LogFile
DS_WriteLog "I" "-Password: ******" $LogFile
DS_WriteLog "I" "-Farm admin group: $FarmAdminGroupName" $LogFile
DS_WriteLog "I" "-Site admin group: $SiteAdminGroupName" $LogFile
DS_WriteLog "I" "-Collection admin group: $CollectionAdminGroupName" $LogFile
DS_WriteLog "I" "-Max password age: $MaxPasswordAge" $LogFile
DS_WriteLog "I" "-UNC store name: $UNCStoreName" $LogFile
DS_WriteLog "I" "-UNC store description: $UNCStoreDescription" $LogFile
DS_WriteLog "I" "-UNC store path: $UNCStorePath" $LogFile

DS_WriteLog "-" "" $LogFile

# ---------------------------------------------------------------------------------------------------------------------------
#region firewall
#################################################
# CONFIGURE THE LOCAL FIREWALL                  #
#################################################

# Note 1: The local firewall is not configured during the installation of Provisioning Server
# Note 2: in case you use a Microsoft Group Policy object to configure the firewall, you can delete the following lines of code

DS_WriteLog "I" "Create the firewall rules" $LogFile
DS_WriteLog "-" "=========================" $LogFile

# Create the inbound rule for the TCP ports
DS_CreateFirewallRule -Name "Citrix PVS (Inbound,TCP)" -Description "Inbound rules for the TCP protocol for Citrix Provisioning Server ports" -Ports "389,1433,54321-54323" -Protocol "TCP" -Direction "Inbound" -Action "Allow"
DS_WriteLog "-" "" $LogFile
# Create the inbound rule for the UDP ports
DS_CreateFirewallRule -Name "Citrix PVS (Inbound,UDP)" -Description "Inbound rules for the UDP protocol for Citrix Provisioning Server ports" -Ports "67,69,2071,6910-6930,6969,4011,6890-6909" -Protocol "UDP" -Direction "Inbound" -Action "Allow"
DS_WriteLog "-" "" $LogFile
# Create the outbound rule for the TCP ports
DS_CreateFirewallRule -Name "Citrix PVS (Outbound,TCP)" -Description "Outbound rules for the TCP protocol for Citrix Provisioning Server ports" -Ports "389,1433,54321-54323" -Protocol "TCP" -Direction "Outbound" -Action "Allow"
DS_WriteLog "-" "" $LogFile
# Create the outbound rule for the UDP ports
DS_CreateFirewallRule -Name "Citrix PVS (Outbound,UDP)" -Description "Outbound rules for the UDP protocol for Citrix Provisioning Server ports" -Ports "67,69,2071,6910-6930,6969,4011,6890-6909" -Protocol "UDP" -Direction "Outbound" -Action "Allow"

DS_WriteLog "-" "" $LogFile

#endregion
#region Create of Join Farm
#################################################
# CREATE OR JOIN THE PROVISIONING SERVER FARM   #
#################################################

DS_WriteLog "I" "Create or join the provisioning server farm" $LogFile
DS_WriteLog "-" "===========================================" $LogFile

# A Provisioning Server farm can only be created using the ConfigWizard.exe and an accompanying configuration file (*.ans).
# The same goes for joining a Provisioning Server farm.
# The ConfigWizard.exe is located here: "%programfiles%\Citrix\Provisioning Services\ConfigWizard.exe"
# The ANS-file can be created in any editor such as Notepad and has to be saved as Unicode.
# The possible parameters that can be used in the ANS-file can be found by executing the following command:
#
#           "%programfiles%\Citrix\Provisioning Services\ConfigWizard.exe" /C
#
# This command generates the following output file: C:\ProgramData\Citrix\Provisioning Services\ConfigWizard.out
# This output file can be opened in any editor (such as Notepad). The contents of this file is a complete list of
# all possible ConfigWizard parameters.
#
# If you run the ConfigWizard.exe with the /S parameter, all steps in the wizard are recorded to an ANS file in the directory
# C:\ProgramData\Citrix\Provisioning Services.
#
# The native command to execute the ConfigWitward with the ANS file is:
#
#           "%programfiles%\Citrix\Provisioning Services\ConfigWizard.exe" /a:C:\ConfigWizard.ans /o:C:\ConfigWizard.log

#region Get IPv4
# Get the IPv4 address of the main network card
DS_WriteLog "I" "Get the IPv4 address of the main network card" $LogFile
try {
    $AvailableNICs = gwmi Win32_NetworkAdapter -Filter "NetEnabled='True'"
    switch ($AvailableNICs.Count)
    { 
        {$_ -eq 0 } {
            DS_WriteLog "E" "No enabled network card could be found!" $LogFile
            DS_WriteLog "E" "Please make sure at least one network card exists and is connected to the network before running this script again." $LogFile
            Exit 1
        }
        {$_ -gt 1 } {
            DS_WriteLog "E" "More than one enabled network card was found! This script cannot determine which network card to use." $LogFile
            DS_WriteLog "E" "Please enter the preferred IP address in the variable '$StreamingIP' and '$BootIP' and run this script again." $LogFile
            Exit 1
        }
        default {
            DS_WriteLog "I" "One enabled network card was found. Retrieve the IP address." $LogFile
            ForEach ($Adapter in $AvailableNICs) {
                $IPv4Address = $(gwmi Win32_NetworkAdapterConfiguration -Filter "Index = '$($Adapter.Index)'").IPAddress
            }
            DS_WriteLog "I" "The IPv4 address of the main network card is $IPv4Address" $LogFile
        }   
    }
} catch {
    DS_WriteLog "E" "An error occurred trying to retrieve the IPv4 address (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile
#endregion
#region Create Answer File - Create Farm
# Define the variables for the ANS file for CREATING a NEW farm
#
#                                              Add your values here:
#                                            |||||||||||||||||||||||||
#                                            vvvvvvvvvvvvvvvvvvvvvvvvv
$Text += "FarmConfiguration="              + "1"                                                                  + "`r`n"   # 0 = farm already configures, 1= create farm, 2 = join farm
$Text += "BootstrapFile="                  + "C:\ProgramData\Citrix\Provisioning Services\Tftpboot\ARDBP32.BIN"   + "`r`n"   # Set the boot strap file for the PVS TFTP service. Leave out this parameter if you do not want to use the PVS TFTP service
$Text += "DatabaseServer="                 + $DatabaseServer                                                      + "`r`n"   # The name of the database (SQL) server
if ( !([string]::IsNullOrEmpty($DatabaseInstance)) ) {
    $Text += "DatabaseInstance="           + $DatabaseInstance                                                    + "`r`n"   # The name of the database instance. Leave out this parameter if there is only one (default) instance on your SQL server
}
$Text += "DatabaseNew="                    + $DatabaseName                                                        + "`r`n"   # The name of the database
$Text += "FarmNew="                        + $FarmName                                                            + "`r`n"   # The name of the Provisioning Server farm
$Text += "SiteNew="                        + $SiteName                                                            + "`r`n"   # The name of the default site
$Text += "CollectionNew="                  + $DefaultCollectionName                                               + "`r`n"   # The name of the default collection
$Text += "Store="                          + $DefaultStoreName                                                    + "`r`n"   # The name of the default store
$Text += "DefaultPath="                    + $DefaultStorePath                                                    + "`r`n"   # The path to the default store (this directory is created below to avoid errors)
$Text += "PasswordManagementInterval="     + $MaxPasswordAge                                                      + "`r`n"   # Automate computer password updates (number of days between password updates). Leave out this parameter if you do not want PVS to manage the password updates
$Text += "LicenseServer="                  + $LicenseServer                                                       + "`r`n"   # The name of the Citrix license server
$Text += "LicenseServerPort="              + $LicenseServerPort                                                   + "`r`n"   # The port of the Citrix license server used for the initial connection (27000 by default)
if ( [string]::IsNullOrEmpty($StreamingIP) ) {
    $Text += "LS1="                        + "$($IPv4Address),0.0.0.0,0.0.0.0,$FirstStreamingPort"                + "`r`n"   # The IPv4 address of the local server to be added to the stream servers boot list 
} else {
    $Text += "LS1="                        + "$($StreamingIP),0.0.0.0,0.0.0.0,$FirstStreamingPort"                + "`r`n"   # The IPv4 address of the local server to be added to the stream servers boot list 
}
if ( [string]::IsNullOrEmpty($BootIP) ) {
    $Text += "StreamNetworkAdapterIP="     + $IPv4Address                                                         + "`r`n"   # Set the network adapter IP for the stream servers (comma delimited IP address list). The first card is used if you leave out this parameter
} else {
    $Text += "StreamNetworkAdapterIP="     + $BootIP                                                              + "`r`n"   # Set the network adapter IP for the stream servers (comma delimited IP address list). The first card is used if you leave out this parameter
}
$Text += "UserName="                       + $UserName                                                            + "`r`n"   # The name of a user with SQL sysadmin rights
$Text += "UserPass="                       + $Password                                                            + "`r`n"   # The password of the user with SQL sysadmin rights. Either use UserPass (plain text) or UserName2 (encrypted) for the password.

# Create the Config Wizard ANS file for CREATING a NEW farm
$ConfWizardANSFileCreateFarm = "$env:Temp\ConfigWizardCreateFarm.ans"
DS_WriteLog "I" "Create the configuration file '$ConfWizardANSFileCreateFarm'" $LogFile
try {
    Set-Content $ConfWizardANSFileCreateFarm -value ($Text) -Encoding Unicode
    DS_WriteLog "S" "The configuration file '$ConfWizardANSFileCreateFarm' was created successfully" $LogFile
 } catch {
    DS_WriteLog "E" "An error occurred trying to create the configuration file '$ConfWizardANSFileCreateFarm' (error: $($Error[0]))" $LogFile
    Exit 1
 }

# Reset/empty the variable $Text
Clear-Variable Text
#endregion
#region Create Answer File - Join Farm
# Define the variables for the ANS file for JOINING an EXISTING farm
#
#                                              Add your values here:
#                                            |||||||||||||||||||||||||
#                                            vvvvvvvvvvvvvvvvvvvvvvvvv
$Text += "FarmConfiguration="              + "2"                                                                  + "`r`n"   # 0 = farm already configures, 1= create farm, 2 = join farm
$Text += "DatabaseServer="                 + $DatabaseServer                                                      + "`r`n"   # The name of the database (SQL) server
if ( !([string]::IsNullOrEmpty($DatabaseInstance)) ) {
    $Text += "DatabaseInstance="           + $DatabaseInstance                                                    + "`r`n"   # The name of the database instance. Leave out this parameter if there is only one (default) instance on your SQL server
}
$Text += "FarmExisting="                   + $FarmName                                                            + "`r`n"   # The name of the Provisioning Server farm
$Text += "ExistingSite="                   + $SiteName                                                            + "`r`n"   # The name of the default site
$Text += "ExistingStore="                  + $DefaultStoreName                                                    + "`r`n"   # The name of the default store
if ( [string]::IsNullOrEmpty($StreamingIP) ) {
    $Text += "LS1="                        + "$($IPv4Address),0.0.0.0,0.0.0.0,$FirstStreamingPort"                + "`r`n"   # The IPv4 address of the local server to be added to the stream servers boot list 
} else {
    $Text += "LS1="                        + "$($StreamingIP),0.0.0.0,0.0.0.0,$FirstStreamingPort"                + "`r`n"   # The IPv4 address of the local server to be added to the stream servers boot list 
}
if ( [string]::IsNullOrEmpty($BootIP) ) {
    $Text += "StreamNetworkAdapterIP="     + $IPv4Address                                                         + "`r`n"   # Set the network adapter IP for the stream servers (comma delimited IP address list). The first card is used if you leave out this parameter
} else {
    $Text += "StreamNetworkAdapterIP="     + $BootIP                                                              + "`r`n"   # Set the network adapter IP for the stream servers (comma delimited IP address list). The first card is used if you leave out this parameter
}
$Text += "PasswordManagementInterval="     + $MaxPasswordAge                                                      + "`r`n"   # Automate computer password updates (number of days between password updates). Leave out this parameter if you do not want PVS to manage the password updates
$Text += "UserName="                       + $UserName                                                            + "`r`n"   # The name of a user with SQL sysadmin rights
$Text += "UserPass="                       + $Password                                                            + "`r`n"   # The password of the user with SQL sysadmin rights. Either use UserPass (plain text) or UserName2 (encrypted) for the password.


# Create the Config Wizard ANS file for JOINING an EXISTING farm
$ConfWizardANSFileJoinFarm = "$env:Temp\ConfigWizardJoinFarm.ans"
DS_WriteLog "I" "Create the configuration file '$ConfWizardANSFileJoinFarm'" $LogFile
try {
    Set-Content $ConfWizardANSFileJoinFarm -value ($Text) -Encoding Unicode
    DS_WriteLog "S" "The configuration file '$ConfWizardANSFileJoinFarm' was created successfully" $LogFile
 } catch {
    DS_WriteLog "E" "An error occurred trying to create the configuration file '$ConfWizardANSFileJoinFarm' (error: $($Error[0]))" $LogFile
    Exit 1
 }

DS_WriteLog "-" "" $LogFile
#endregion
#region ConfigWizard
# Before executing the ConfigWizard.exe, create the directory for the default PVS store (the config wizard ends in an error if the path does not exist)
DS_WriteLog "I" "Create the directory for the default PVS store (otherwise the config wizard ends in an error)" $LogFile
DS_CreateDirectory -Directory $DefaultStorePath

DS_WriteLog "-" "" $LogFile

# Delete the ConfigWizard log file (if exist)
$ConfigWizardLogFile = "$LogDir\ConfigWizard.log"
DS_WriteLog "I" "Delete the ConfigWizard log file '$ConfigWizardLogFile'" $LogFile
DS_DeleteFile -File $ConfigWizardLogFile

DS_WriteLog "-" "" $LogFile

# Execute the ConfigWizard and either join or create the Provisioning Server farm
$ConfigWizardEXE = "$env:ProgramFiles\Citrix\Provisioning Services\ConfigWizard.exe"
DS_WriteLog "I" "Create a new farm (execute the ConfigWizard)" $LogFile
if ( Test-Path $ConfigWizardEXE ) {
    # Create the farm
    $params = "/a:$ConfWizardANSFileCreateFarm /o:$ConfigWizardLogFile"
    DS_WriteLog "I" "Command: $ConfigWizardEXE $params -WindowStyle Hidden -Wait" $LogFile   
    start-process $ConfigWizardEXE $params -WindowStyle Hidden -Wait  # There is no need for a try / catch statement since the ConfigWizard always exists with code 0
    
    # The ConfigWizard only provides the exit code 0. We have to read the log file to check the result.
    [string]$GetText = Get-Content $ConfigWizardLogFile
    switch -wildcard ($GetText)
    { 
        "*Invalid Database Name*" {
            DS_WriteLog "I" "The Provisioning Server farm $($FarmName.ToUpper()) already exists!" $LogFile
            DS_WriteLog "I" "Join this server to the existing Provisioning Server farm $($FarmName.ToUpper())" $LogFile

            # Delete the ConfigWizard log file (if exist)
            $ConfigWizardLogFile = "$LogDir\ConfigWizard.log"
            DS_WriteLog "I" "Delete the ConfigWizard log file '$ConfigWizardLogFile'" $LogFile
            DS_DeleteFile -File $ConfigWizardLogFile

            # Join the server to the farm
            $params = "/a:$ConfWizardANSFileJoinFarm /o:$ConfigWizardLogFile"
            DS_WriteLog "I" "Command: $ConfigWizardEXE $params -WindowStyle Hidden -Wait" $LogFile   
            start-process $ConfigWizardEXE $params -WindowStyle Hidden -Wait  # There is no need for a try / catch statement since the ConfigWizard always exists with code 0
            
            # The ConfigWizard only provides the exit code 0. We have to read the log file to check the result.
            [string]$GetText = Get-Content $ConfigWizardLogFile
            if ( $GetText.Contains("Configuration complete") ) {
                DS_WriteLog "S" "The server was successfully joined to the Provisioning Server farm $($FarmName.ToUpper())!" $LogFile
            } else {
                DS_WriteLog "E" "An error occurred trying to join the server to the Provisioning Server farm $($FarmName.ToUpper())!" $LogFile
                Exit 1
            }
        } 
        "*Configuration complete*" { 
            DS_WriteLog "S" "The Provisioning Server farm $($FarmName.ToUpper()) was created successfully!" $LogFile
        }
        "*Fatal error*" { 
            DS_WriteLog "E" "A fatal error occurred trying to create the Provisioning Server farm $($FarmName.ToUpper())!" $LogFile
        }
    }
    DS_WriteLog "I" "For more information see the log file $ConfigWizardLogFile" $LogFile
} else {
    DS_WriteLog "E" "The file $ConfigWizardEXE does not exist!" $LogFile
}

DS_WriteLog "-" "" $LogFile

# Delete the ConfigWizard configuration file (since it contains the password of the Active Directory service account in plain text)
DS_WriteLog "I" "Delete the ConfigWizard configuration file '$ConfWizardANSFileCreateFarm'" $LogFile
DS_DeleteFile -File $ConfWizardANSFileCreateFarm
DS_WriteLog "I" "Delete the ConfigWizard configuration file '$ConfWizardANSFileJoinFarm'" $LogFile
DS_DeleteFile -File $ConfWizardANSFileJoinFarm

DS_WriteLog "-" "" $LogFile
#endregion
#endregion
#region Config Provisioning Server
#############################################################
# CONFIGURE THE PROVISIONING SERVER FARM AND THE LOCAL HOST #
#############################################################

DS_WriteLog "I" "Configure the Provisioning Server farm and the local host" $LogFile
DS_WriteLog "I" "=========================================================" $LogFile

# Load the Citrix snap-ins
# ========================
DS_WriteLog "I" "Load the Citrix snap-ins" $LogFile
try {
    asnp citrix*
    DS_WriteLog "S" "The Citrix snap-ins were loaded successfully" $LogFile
} catch {
    DS_WriteLog "E" "An error occurred trying to load the Citrix snap-ins (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile

# Create three new authorization groups
# =====================================
DS_CreatePVSAuthGroup -GroupName $FarmAdminGroupName         # Farm admin group
DS_CreatePVSAuthGroup -GroupName $SiteAdminGroupName         # Site admin group
DS_CreatePVSAuthGroup -GroupName $CollectionAdminGroupName   # Collection admin group

DS_WriteLog "-" "" $LogFile

# Grant the authorization groups the appropriate admin rights
# ===========================================================
DS_GrantPVSAuthGroupAdminRights -GroupName $FarmAdminGroupName                                                                      # Grant farm admin rights
DS_GrantPVSAuthGroupAdminRights -GroupName $SiteAdminGroupName -SiteName $SiteName                                                  # Grant site admin rights
DS_GrantPVSAuthGroupAdminRights -GroupName $CollectionAdminGroupName -SiteName $SiteName -CollectionName $DefaultCollectionName     # Grant collection admin rights

DS_WriteLog "-" "" $LogFile

# Configure the Provisioning Server farm
# ======================================
DS_WriteLog "I" "Configure the Provisioning Server farm" $LogFile
DS_WriteLog "I" "-Enable auditing" $LogFile
DS_WriteLog "I" "-Enable offline database support" $LogFile
DS_WriteLog "I" "-Register license server" $LogFile
DS_WriteLog "I" "-Register license server port" $LogFile
try {
    Set-PvsFarm -AuditingEnabled -OfflineDatabaseSupportEnabled -LicenseServer $LicenseServer -LicenseServerPort $LicenseServerPort
    DS_WriteLog "S" "The Provisioning Server farm settings have been successfully configured" $LogFile
} catch {
    DS_WriteLog "E" "An error occurred trying to configure the Provisioning Server farm settings (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile

# Enable the Customer Experience Improvements Program (CEIP)
# ======================================================
DS_WriteLog "I" "Enable the Customer Experience Improvements Program (CEIP)" $LogFile
try {
    Set-PvsCeipData -enabled 1
    DS_WriteLog "S" "CEIP has been successfully enabled" $LogFile
} catch {
    DS_WriteLog "E" "An error occurred trying to enable CEIP (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile

# Enable verbose mode in the bootstrap configuration
# ==================================================
DS_WriteLog "I" "Enable verbose mode in the bootstrap configuration" $LogFile
try {
    Set-PvsServerBootstrap -Name "ARDBP32.bin" -ServerName $env:ComputerName -VerboseMode
    DS_WriteLog "S" "Verbose mode has been enabled" $LogFile
} catch {
    DS_WriteLog "E" "An error occurred trying to enable verbose mode (error: $($Error[0]))" $LogFile
    #Exit 1
}

DS_WriteLog "-" "" $LogFile

# Configure the local host
# ========================
DS_WriteLog "I" "Configure the local host" $LogFile
$NumberOfCores = (gwmi win32_ComputerSystem).numberoflogicalprocessors   # this is the total number of cores including hyperthreading
if ( $NumberOfCores -lt 8 ) { $NumberOfCores = 8 }                       # set the threads per port to the default value of 8 in case the number of logical cores is less than 8
DS_WriteLog "I" "-Set first streaming port" $LogFile
DS_WriteLog "I" "-Set last streaming port" $LogFile
DS_WriteLog "I" "-Set the threads per port equal to the number of vCPUs/virtual cores" $LogFile
DS_WriteLog "I" "-Set max password age to" $LogFile
DS_WriteLog "I" "-Enable max password age" $LogFile
DS_WriteLog "I" "-Enable write log to Windows event log" $LogFile
try {
    Set-PvsServer -ServerName $env:ComputerName -FirstPort $FirstStreamingPort -LastPort $LastStreamingPort -ThreadsPerPort $NumberOfCores -AdMaxPasswordAge $MaxPasswordAge -AdMaxPasswordAgeEnabled -EventLoggingEnabled
    DS_WriteLog "S" "The PVS settings on the local host were configured successfully" $LogFile
} catch {
    DS_WriteLog "E" "An error occurred trying to configure the PVS settings on the local host (error: $($Error[0]))" $LogFile
    Exit 1
}

DS_WriteLog "-" "" $LogFile

# Create a new farm-wide PVS store (UNC)
# Note: the PVS store can be created even if the directory or UNC path does not exist
# ===================================================================================
DS_WriteLog "I" "Create the PVS store $UNCStoreName" $LogFile
try { 
    Get-PvsStore -Name $UNCStoreName | Out-Null
    DS_WriteLog "I" "The PVS store $UNCStoreName already exists. Nothing to do." $LogFile
} catch {
    try {
        New-PvsStore -Name $UNCStoreName -Path $UNCStorePath -Description $UNCStoreDescription | Out-Null
        DS_WriteLog "S" "The PVS store '$UNCStoreName' was created successfully" $LogFile
    } catch {
        DS_WriteLog "E" "An error occurred trying to create the PVS store '$UNCStoreName' (error: $($Error[0]))" $LogFile
        Exit 1
    }
}

DS_WriteLog "-" "" $LogFile

# Add the local server to a PVS store
# ===================================
DS_WriteLog "I" "Add the local server to the PVS store '$UNCStoreName'" $LogFile
try { 
    Set-PvsServerStore -ServerName $ComputerName -StoreName $UNCStoreName | Out-Null
    DS_WriteLog "S" "The local server has been successfully added to the PVS store '$UNCStoreName'" $LogFile
} catch {
    [string]$ErrorText = $Error[0]
    If ( $ErrorText.Contains("No object was added")) {
        DS_WriteLog "I" "The server has already been added to the PVS store '$UNCStoreName'. Nothing to do." $LogFile
    } else {
        DS_WriteLog "E" "An error occurred trying to add the local host to the PVS store '$UNCStoreName' (error: $($Error[0]))" $LogFile
        Exit 1
    }    
}

DS_WriteLog "-" "" $LogFile

# Disable BIOS Boot Menu
# Reference: http://www.carlstalhood.com/provisioning-services-server-install/#bootmenu
# ======================
DS_SetRegistryValue -RegKeyPath "hklm:\Software\Citrix\ProvisioningServices\StreamProcess" -RegValueName "SkipBootMenu" -RegValue "1" -Type "DWORD"

# Fix error: No servers available for disk When Booting from vDisk
# Reference: https://support.citrix.com/article/CTX200233
# ======================
DS_SetRegistryValue -RegKeyPath "hklm:\Software\Citrix\ProvisioningServices\StreamProcess" -RegValueName "SkipRIMSForPrivate" -RegValue "1" -Type "DWORD"


# Enable File Security  
Remove-Item env:\SEE_MASK_NOZONECHECKS

DS_WriteLog "-" "" $LogFile
DS_WriteLog "I" "End of script" $LogFile