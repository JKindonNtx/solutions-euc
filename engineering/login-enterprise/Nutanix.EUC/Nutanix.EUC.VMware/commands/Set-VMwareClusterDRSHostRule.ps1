function Set-VMwareClusterDRSHostRule {
    
    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $true)][string]$VMGroupName,
        [Parameter(Mandatory = $true)][string]$Cluster,
        [Parameter(Mandatory = $true)][string]$HostGroupName
    )

    $DRSRuleName = "$VMGroupName to $HostGroupName"
    
    try {
        $ExistingRule = Get-DrsVMHostRule -Name $DRSRuleName -ErrorAction Stop
        if (-not [string]::IsNullOrEmpty($ExistingRule)) {
            #Group Already Exists
            Write-Log -Message "DRS VM Host Rule: $($ExistingRule) already exists" -Level Info
        }
    }
    catch {
        # group doesn't Exist
        #Write-Log -Message "DRS VM Host Rule: $($DRSRuleName) doesn't exist. Creating" -Level Info
        try {
            $NewDRSRule = New-DrsVMHostRule -Name $DRSRuleName -Cluster $Cluster -VMGroup $VMGroupName -VMHostGroup $HostGroupName -Type MustRunOn -Enabled $true -ErrorAction Stop
            Write-Log -Message "DRS VM Host Rule $($NewDRSRule.Name) created on Cluster $($Cluster)" -Level Info
        }
        catch {
            Write-Log -Message "DRS VM Host Rule Failed to create" -Level Warn
            Write-Log -Message "$_" -Level Warn
        }
    }

    #return ??
}