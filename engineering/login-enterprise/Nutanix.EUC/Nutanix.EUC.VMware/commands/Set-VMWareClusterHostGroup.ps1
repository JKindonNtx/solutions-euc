function Set-VMWareClusterHostGroup {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$HostGroupName,
        [Parameter(Mandatory = $true)][string]$Cluster,
        [Parameter(Mandatory = $true)][string]$VMHost
    )
    
    try {
        $ExistingGroup = Get-DrsClusterGroup -Name $HostGroupName -Type VMHostGroup -ErrorAction Stop
        if (-not [string]::IsNullOrEmpty($ExistingGroup)) {
            #Group Already Exists
            Write-Log -Message "DRS Host Group: $($HostGroupName) already exists. Validating membership" -Level Info
            #Make sure that only our host is in this group
            $ExistingGroupMembers = $ExistingGroup.Member.Name
            foreach ($Member in $ExistingGroupMembers | Where-Object {$_ -ne $VMHost}) {
                try {
                    $RemoveHostFromGroup = Set-DrsClusterGroup -DrsClusterGroup $HostGroupName -VMHost $Member -Remove -ErrorAction Stop
                    Write-Log -Message "Removed $($Member) from Host Group: $($HostGroupName)" -Level Info
                }
                catch {
                    Write-Log -Message "Failed to remove $($Member) from Host Group: $($HostGroupName)" -Level Warn
                    Write-Log -Message "$_" -Level Warn
                }  
            }
        }
    }
    catch {
        # group doesn't exist
        try {
            $NewHostGroup = New-DrsClusterGroup -Name $HostGroupName -Cluster $Cluster -VMHost $VMHost -ErrorAction Stop
            Write-Log "DRS Host Group $($NewHostGroup.Name) created on Cluster $($NewHostGroup.Cluster) with Host $($NewHostGroup.Member[0])"
        }
        catch {
            Write-Log -Message "Host Group Failed to create" -Level Warn
            Write-Log -Message "$_" -Level Warn
        }
    }

    #return ??

}