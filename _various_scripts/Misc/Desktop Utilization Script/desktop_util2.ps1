<#
.SYNOPSIS
    Creates a complete inventory of a Nutanix environment.
.DESCRIPTION
    Creates a complete inventory of a Nutanix Cluster configuration using CSV and PowerShell.

.PARAMETER nxIP
    IP address of the Nutanix node you're making a connection too.
.PARAMETER nxUser
    Username for the connection to the Nutanix node
.PARAMETER nxPassword
    Password for the connection to the Nutanix node

.EXAMPLE
    PS C:\PSScript > .\nutanix_inventory.ps1 -nxIP "99.99.99.99.99" -nxUser "admin"
.INPUTS
    None.  You cannot pipe objects to this script.
.OUTPUTS
    No objects are output from this script.  
    This script creates a CSV file.
.NOTES
    NAME: Nutanix_Inventory_Script_v1.ps1
    VERSION: 1.0
    AUTHOR: Kees Baggerman with help from Andrew Morgan
    LASTEDIT: February 2017
#>

$ADSearchBase = "OU=Computers,OU=CORP,DC=Contoso,DC=Local"
$DDC = "CONTMXD001.contoso.local"
 

# To get all user objects who have not logged on since January 1, 2007, use the following commands:
# $logonDate = New-Object System.DateTime(2007, 1, 1)
# Get-ADUser -filter { lastLogon -le $logonDate }

# Grabbing the AD portion of the script, determining which desktops are not logged onto the last 31 days

Import-Module ActiveDirectory
Add-PSSnapin Citrix*

$logonDate = (get-date).AddDays(-31)

# $A = get-ADComputer -Filter { lastLogon -le $logonDate } -Properties * -SearchBase $ADSearchBase | Sort LastLogonDate | FT Name #, LastLogonDate -Autosize 

# Collecting Pre-assinged desktops from XenDesktop


$Desktops = Get-BrokerDesktop -maxrecordcount 5000 -adminaddress $DDC | Select-Object HostedMachineName #, AssociatedUserNames,AssociatedUserFullNames

foreach($Desktop in $Desktops){
            get-ADComputer -Identity $desktops.HostedMachineName -Filter { lastLogon -le $logonDate } -Properties * | Sort LastLogonDate | FT Name
        }