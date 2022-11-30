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

function Get-UserId ($User) {

  $defn = New-Object VMware.Hv.QueryDefinition
  $defn.queryEntityType = 'ADUserOrGroupSummaryView'
  [VMware.Hv.QueryFilter[]]$filters = $null
  $groupfilter = New-Object VMware.Hv.QueryFilterEquals -Property @{ 'memberName' = 'base.group'; 'value' = $false }
  $userNameFilter = New-Object VMware.Hv.QueryFilterEquals -Property @{ 'memberName' = 'base.name'; 'value' = $user }
  $treeList = @()
  $treeList += $userNameFilter
  $treelist += $groupfilter
  $filterAnd = New-Object VMware.Hv.QueryFilterAnd
  $filterAnd.Filters = $treelist
  $defn.Filter = $filterAnd
  $query_service_helper = New-Object VMware.Hv.QueryServiceService
  $res = $query_service_helper.QueryService_Query($services,$defn)
  if ($null -eq $res.results) {
    throw "Query service did not return any users with given user name: [$user]"
  }
  return $res.results.id
}

Function Get-HVDesktop {
    <#  
    .SYNOPSIS  
        This cmdlet retrieves the virtual desktops on a horizon view Server (Originating from https://github.com/vmware/PowerCLI-Example-Scripts/blob/master/Scripts/Horizon%20View%20Example%20Desktop%20Script.ps1)
    .DESCRIPTION 
        This cmdlet retrieves the virtual desktops on a horizon view Server.
    .NOTES  
        Author:  Alan Renouf, @alanrenouf,virtu-al.net
    .PARAMETER State
        Hash table containing states to filter on
    .EXAMPLE
	    List All Desktops
        Get-HVDesktop
    .EXAMPLE
        List All Problem Desktops
        Get-HVDesktop -state @('PROVISIONING_ERROR', 
                        'ERROR', 
                        'AGENT_UNREACHABLE', 
                        'AGENT_ERR_STARTUP_IN_PROGRESS',
                        'AGENT_ERR_DISABLED', 
                        'AGENT_ERR_INVALID_IP', 
                        'AGENT_ERR_NEED_REBOOT', 
                        'AGENT_ERR_PROTOCOL_FAILURE', 
                        'AGENT_ERR_DOMAIN_FAILURE', 
                        'AGENT_CONFIG_ERROR', 
                        'UNKNOWN')
    #>
Param (
        $State
    )
    
    $ViewAPI = $global:DefaultHVServers[0].ExtensionData
    $query_service = New-Object "Vmware.Hv.QueryServiceService"
    $query = New-Object "Vmware.Hv.QueryDefinition"
    $query.queryEntityType = 'MachineSummaryView'
    if ($State) {
        [VMware.Hv.QueryFilter []] $filters = @()
        foreach ($filterstate in $State) {
            $filters += new-object VMware.Hv.QueryFilterEquals -property @{'memberName' = 'base.basicState'; 'value' = $filterstate}
        }
        $orFilter = new-object VMware.Hv.QueryFilterOr -property @{'filters' =  $filters}
        $query.Filter = $orFilter
    }
    $Desktops = $query_service.QueryService_Query($ViewAPI,$query)
    $Desktops.Results.Base
}

<#

# Setting the variables for this script
$adminmail = "k.baggerman@hotmail.com"
$cred = get-credential

# Importing the proper cmdlets
Import-Module ActiveDirectory
Import-Module VMware.VimAutomation.HorizonView
 
# Grabbing the AD portion of the script, determining which desktops are not logged onto the last 31 days
$logonDate = (get-date).AddDays(-31)
$ADDesktops = get-ADComputer -Filter { lastLogon -le $logonDate } -Properties *$dd | Sort LastLogonDate | FT Name #, LastLogonDate -Autosize 

# Connecting to the Horizon View environment and getting the current provisioned desktops
Connect-HVServer -Server CONTMVCS001 -User Administrator -Password nutanix/4u -Domain Contoso.local
$HVDesktops = Get-HVDesktop

# Getting the desktops that are in AD and are used in a Desktop Pool and storing them in a variable
$UnUsedDesktops = Compare-Object $ADDesktops $HVDesktops -Property 'Name'

# Loop through the results, fetch the corresponding email address of the user account and send out an email with a BCC to an additional email address
foreach($Desktop in $UnUsedDesktops){
                               $user = Get-ADUser $hvdesktops.user -Properties *
                               $ComputerName = $hvdesktops.Name
                               $body = “Your desktop ($ComputerName) will be deleted within 3 days”
                               Send-MailMessage -To $user.EmailAddress -bcc $adminmail -from kees@nutanix.com -Subject 'Your Virtual Desktop will be deleted soon' -Body $body -BodyAsHtml -smtpserver smtp.office365.com -usessl -Credential $cred -Port 587 
                               }
#>