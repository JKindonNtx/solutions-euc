function Set-OmnissaVMsAhv {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$BaseVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][Int]$NumberOfVMs,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$NamingConvention,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$StartIndex,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$Domain,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$HostName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$AdminUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$AdminPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$OU,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$RootPath

    )

    Write-Log -Message "Getting Omnissa Base VM UUID" -Level Info
    $var_Omnissa_Base_Vm_Uuid = (Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq $BaseVM }).uuid

    if ($null -eq $var_Omnissa_Base_Vm_Uuid){

        Write-Log -Message "Omnissa Base VM $($BaseVM) Not Found" -Level Error
        Break

    } else {

        Write-Log -Message "Base VM UUID: $($var_Omnissa_Base_Vm_Uuid)" -Level Info
        Write-Log -Message "Starting Build of $($NumberOfVMs) VMs" -Level Info

        $var_Number_Padding = ([regex]::Matches($NamingConvention, "#" )).count
        $var_Naming_Convention_Base = $NamingConvention.replace("#", "")   

        $machineNames = New-Object System.Collections.Generic.List[System.Object]

        For ($i = 1; $i -le $NumberOfVMs; $i++) {
            
            $var_Machine_Prefix = $StartIndex.PadLeft($var_Number_Padding, "0")
            $var_Machine_Name = "$($var_Naming_Convention_Base)$($var_Machine_Prefix)"
            $var_Prefix_Int = [int]$StartIndex
            $var_Prefix_Int++
            $StartIndex = [string]$var_Prefix_Int

            $var_Unattend = Get-UnattendFile -DomainJoin $true -Domain $Domain -HostName $var_Machine_Name -AdminUserName $AdminUserName -AdminPassword $AdminPassword -OU $OU

            $Payload = "{ `
            ""spec_list"": [ `
                { `
                    ""name"": """ + $var_Machine_Name + """ `
                } `
            ], `
                ""vm_customization_config"": { `
                ""userdata"": """ + $var_Unattend + """ `
                } `
            }"

            Write-Log -Update -Message "Deploying Machine $($i) of $($NumberOfVMs)." -Level Info
            $var_result = Set-NTNXVmClone -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -VmUuid $var_Omnissa_Base_Vm_Uuid -Body $Payload

            $machineNames.Add($var_Machine_Name)
        }

        # Get Tasks from PE
        # Loop Until all tasks complete - 5 second loop
        # Write log with update task complete
        Write-Log -Message "Sleeping 30 Seconds to let deployment complete" -Level Info
        Start-Sleep -Seconds 30

        $i = 1
        foreach ($var_VM in $machineNames) {
            Write-Log -Update -Message "Turning On Machine $($i) of $($NumberOfVMs)." -Level Info
            $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($var_VM)" }
            $var_Power_Result = Set-VmPower -VmUuid $CurrentVM.uuid -PowerState "ON" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword
            $i++
        }

        # Check for Computer Object in AD using the Omnissa Api
        # Count here needs to equal the number of desktops
        Write-Log -Message "Waiting 1 minute to let VMs settle" -Level Info
        Start-Sleep -Seconds 60

        Write-Log -Message "Checking All VMs have a valid IP Address - Please wait" -Level Info
        do {
            $var_Valid_Ips = $false
            Write-Log -Update -Message "Still waiting for valid IPs on all the VMs - Please wait" -Level Info
            foreach ($var_VM in $machineNames) {
                $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($var_VM)" }
                $var_VM_Details = Get-OmnissaVMsIP -VmUuid $CurrentVM.uuid -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword
                #try catch here for pre boot situation
                $var_VM_IP = $var_VM_Details.vm_nics[0].ip_address
                if([string]::IsNullOrEmpty($var_VM_IP) -Or $var_VM_IP.StartsWith("169.254")) {
                    $var_Valid_Ips = $false
                } else {
                    $var_Valid_Ips = $true
                }
            }
            Write-Log -Update -Message "Still waiting for valid IPs on all the VMs - Please wait" -Level Info
            Start-Sleep -Seconds 5
        } While ($var_Valid_Ips -eq $false)
        Write-Log -Message "IP Addresses Validated - Continuing" -Level Info

        Write-Log -Message "Waiting 1 minute to let VM services start up" -Level Info
        Start-Sleep -Seconds 60

        $var_Inventory_List = ""
        foreach ($var_VM in $machineNames) {
            $CurrentVM = Get-NTNXVMS -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword | where-object { $_.name -eq "$($var_VM)" }
            $var_VM_Details = Get-OmnissaVMsIP -VmUuid $CurrentVM.uuid -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword
            $var_VM_IP = $var_VM_Details.vm_nics[0].ip_address
            $var_Inventory_List += "$($var_VM_IP),"
        }
        $var_Inventory_List_Cleaned = $var_Inventory_List.Substring(0,$var_Inventory_List.Length - 1)

        Write-Log -Message "Running Optimizations" -Level Info
        $Playbook = $RootPath + "omnissa_manual_pool_post_deployment.yml"
        $command = "ansible-playbook"
        $arguments = "-f 50 -i " + $var_Inventory_List_Cleaned + ", " + $playbook
        start-process -filepath $command -argumentlist $arguments -passthru -wait 
        
        return $machineNames

    }
}
