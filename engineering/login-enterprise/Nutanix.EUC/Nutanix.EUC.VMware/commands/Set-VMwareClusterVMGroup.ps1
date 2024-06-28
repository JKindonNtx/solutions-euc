function Set-VMwareClusterVMGroup {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$VMGroupName,
        [Parameter(Mandatory = $true)][string]$Cluster,
        [Parameter(Mandatory = $true)][array]$VMList
    )

    try {
        $ExistingVMGroup = Get-DrsClusterGroup -Name $VMGroupName -Type VMGroup -ErrorAction Stop
        if (-not [string]::IsNullOrEmpty($ExistingVMGroup)) {
            #Group Already Exists
            Write-Log -Message "DRS VM Group: $($VMGroupName) already exists. Validating membership" -Level Info
            $ExistingGroupMembers = $ExistingVMGroup.Member.Name
            # Add new members
            foreach ($Member in $VMList | Where-Object {$_ -notin $ExistingGroupMembers}) {
                try {
                    $AddVMToGroup = Set-DrsClusterGroup -DrsClusterGroup $ExistingVMGroup -VM $Member -Add -ErrorAction Stop
                    Write-Log -Message "Added $($Member) to VM Group: $($VMGroupName)" -Level Info
                }
                catch {
                    Write-Log -Message "Failed to Add $($Member) to VM Group: $($VMGroupName)" -Level Warn
                    Write-Log -Message "$_" -Level Warn
                }
            }
            # Remove bad members
            $MembersToRemove = @()
            foreach ($Member in $ExistingGroupMembers | Where-Object {$_ -notin $VMList}) {
                $MembersToRemove += $Member
            }
            $MembersToRemoveCount = ($MembersToRemove | Measure-Object).Count
            if ($MembersToRemoveCount -gt 0) {
                Write-Log -Message "Removing $($MembersToRemoveCount) machines from VM Group $($VMGroupName)" -Level Info
                try {
                    $RemoveVMFromGroup = Set-DrsClusterGroup -DrsClusterGroup $ExistingVMGroup -VM $MembersToRemove -Remove -ErrorAction Stop
                    Write-Log -Message "Removed $($MembersToRemove) from VM Group: $($VMGroupName)" -Level Info
                }
                catch {
                    Write-Log -Message "Failed to remove $($MembersToRemove) from VM Group: $($VMGroupName)" -Level Warn
                    Write-Log -Message "$_" -Level Warn
                }
            }
            
        }
    }
    catch {
        # group doesn't exist
        try {
            $NewVMGroup = New-DrsClusterGroup -Name $VMGroupName -Cluster $Cluster -VM $VMList -ErrorAction Stop
            Write-Log -Message "DRS VM Group $($NewVMGroup.Name) Created on Cluster $($NewVMGroup.Cluster)" -Level Info
        }
        catch {
            Write-Log -Message "DRS VM Group Failed to create" -Level Warn
            Write-Log -Message "$_" -Level Warn
        }
    }

    #return ??

}