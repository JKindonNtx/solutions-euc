<#
.SYNOPSIS
    Gets all desktops that haven't been used within x amount of days (30 days is the default) and emails the end user.
.DESCRIPTION
    Gets all desktops that haven't been used within x amount of days (30 days is the default) and emails the end user.
.EXAMPLE
    PS C:\PSScript > .\desktop_ultil_v1.ps1
.INPUTS
    None.  You cannot pipe objects to this script.
.OUTPUTS
    No objects are output from this script.  
    This script creates an email to the end user.
.NOTES
    NAME: desktop_ultil_v1.ps1
    VERSION: 1.0
    AUTHOR: Kees Baggermann
    LASTEDIT: April 2017
#>

# Setting the variables for this script
$DDC = "CONTMXD001.contoso.local"
# $dest$cred = get-credential
$adminmail = "k.baggerman@hotmail.com"
 
# Making sure the appropriate cmdlets are loaded, Microsoft RSAT and Citrix PoSH Cmdlets need to be installed
Import-Module ActiveDirectory
Add-PSSnapin Citrix*

# Set current date mines 30 days
$logonDate = (get-date).AddDays(-30)

# Get all pre assigned desktops where the last login date is 30 days or longer
$Desktops = Get-BrokerDesktop -maxrecordcount 5000 -adminaddress $DDC | Select-Object HostedMachineName, AssociatedUserNames,LastConnectionTime | where-object {$_.LastConnectionTime -le $logonDate}

# Loop through the results, fetch the corresponding email address of the user account and send out an email with a BCC to an additional email address
foreach($Desktop in $Desktops){
        $user = Get-ADUser $Desktops.AssociatedUserNames.Split("\")[1] -Properties *
        $ComputerName = $Desktop.HostedMachineName
        $body = “Your desktop ($ComputerName) will be deleted within 3 days”
        Send-MailMessage -To $user.EmailAddress -bcc $adminmail -from kees@nutanix.com -Subject 'Your Virtual Desktop will be deleted soon' -Body $body -BodyAsHtml -smtpserver smtp.office365.com -usessl -Credential $cred -Port 587 
}



# Set current date mines 30 days
$logonDate = (get-date).AddDays(-33)


# Get all pre assigned desktops where the last login date is 30 days or longer
$Desktops = Get-BrokerDesktop -maxrecordcount 5000 -adminaddress $DDC | Select-Object HostedMachineName, AssociatedUserNames,LastConnectionTime | where-object {$_.LastConnectionTime -le $logonDate}

foreach ($desktop in $Desktops) {
        # Set-BrokerPrivateDesktop -AdminAddress $DDC -InMaintenanceMode $true -MachineName $desktop.HostedMachineName
        New-BrokerHostingPowerAction -AdminAddress $DDC -MachineName $desktop.HostedMachineName -Action Shutdown 
        Remove-BrokerMachine -MachineName $desktop.HostedMachineName
}