function Set-VMwareClusterAffinityClear {
    
    # Do this ater Run3 completes
    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$VCenter,
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][string]$ClusterName,
        [Parameter(Mandatory = $true)][string]$DataCenter
    )

    try {
        Write-Log -Message "Connecting to vCenter: $($VCenter)" -Level Info
        $VIServerConnection = Connect-VIServer -Server $VCenter -Port "443" -Protocol "https" -User $User -Password $Password -Force -ErrorAction Stop
        # Get Cluster Details
        Write-Log -Message "Getting Cluster Details for Cluster: $($ClusterName) in Datacenter: $($DataCenter)" -Level Info
        $Cluster = Get-Cluster -Server $VCenter -Name $ClusterName -Location $DataCenter -ErrorAction Stop
    }
    catch {
        Write-Log -Message "$_" -Level Warn
        Continue
    }

    # Get Rules - Remove those: "$VMGroupName to $HostGroupName"
    $ipPattern = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
    $NamePattern = "VMGroup_$ipPattern to HostGroup_$ipPattern"

    $ExistingRules = Get-DrsVMHostRule -Cluster $ClusterName | where-Object { $_.Name -match $NamePattern }
    $ExistingRulesCount = ($ExistingRules | Measure-Object).Count

    if ($ExistingRulesCount -gt 0) {
        Write-Log -Message "Removing $($ExistingRulesCount) DRS Host Rules" -Level Info
        foreach ($Rule in $ExistingRules) {
            try {
                $RuleRemoved = Remove-DrsVMHostRule -Rule $Rule -Confirm:$False -ErrorAction Stop
                Write-Log -Message "Removed DRS Host Rule $($Rule.Name)" -Level Info
            }
            catch {
                Write-Log -Message "Failed to remove DRS Host Rule $($Rule.Name)" -Level Warn
                Write-Log -Message "$_" -Level Warn
            }
        }
    }
    else {
        Write-Log -Message "No DRS Host Rules matching pattern $($NamePattern) to remove" -level Info
    }

    # Get VM Groups - Remove those: "$VMGroupName_ip"
    $ipPattern = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
    $NamePattern = "VMGroup_$ipPattern"

    $ExistingVMGroups = Get-DrsClusterGroup -Cluster $ClusterName -Type VMGroup | Where-Object { $_.Name -match $NamePattern }
    $ExistingVMGroupsCount = ($ExistingVMGroups | Measure-Object).Count

    if ($ExistingVMGroupsCount -gt 0) {
        Write-Log -Message "Removing $($ExistingVMGroupsCount) Cluster VM Groups" -Level Info
        foreach ($Group in $ExistingVMGroups) {
            try {
                $VMGroupRemoved = Remove-DrsClusterGroup -DrsClusterGroup $Group -Confirm:$false -ErrorAction Stop
                Write-Log -Message "Removed Cluster VM Group $($Group.Name)" -Level Info
            }
            catch {
                Write-Log -Message "Failed to remove Cluster VM Group $($Group.Name)" -Level Warn
                Write-Log -Message "$_" -Level Warn
            }
        }
    }
    else {
        Write-Log -Message "No Cluster VM Groups matching pattern $($NamePattern) to remove" -Level Info
    }

    # Get Cluster Groups - Remove those
    $ipPattern = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
    $NamePattern = "HostGroup_$ipPattern"
    
    $ExistingHostGroups = Get-DrsClusterGroup -Cluster $ClusterName -Type VMHostGroup | Where-Object { $_.Name -match $NamePattern }
    $ExistingHostGroupsCount = ($ExistingHostGroups | Measure-Object).Count

    if ($ExistingHostGroupsCount -gt 0) {
        Write-Log -Message "Removing $($ExistingHostGroupsCount) Cluster VM Groups" -Level Info
        foreach ($Group in $ExistingHostGroups) {
            try {
                $HostGroupRemoved = Remove-DrsClusterGroup -DrsClusterGroup $Group -Confirm:$false -ErrorAction Stop
                Write-Log -Message "Removed Cluster Host Group $($Group.Name)" -Level Info
            }
            catch {
                Write-Log -Message "Failed to remove Cluster Host Group $($Group.Name)" -Level Warn
                Write-Log -Message "$_" -Level Warn
            }
        }
    }
    else {
        Write-Log -Message "No Cluster Host Groups matching pattern $($NamePattern) to remove" -Level Info
    }
}