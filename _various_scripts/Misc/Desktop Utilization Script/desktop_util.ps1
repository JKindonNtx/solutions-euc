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