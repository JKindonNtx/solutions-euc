function Set-OmnissaVMsESXi {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VMwareClusterName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VMwareVCenterIP,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VMwareUserName,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VMwarePassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$BaseVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][Int]$NumberOfVMs,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$NamingConvention,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$StartIndex,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$RootPath,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$CustomizationSpec

    )

    if (Test-Path -Path $RootPath -PathType Container) {
        Write-Log -Message "Ansible playbook path $($RootPath) Exists" -Level Info
    } else {
        Write-Log -Message "Ansible playbook path $($RootPath) Does Not Exist" -Level Error
        Exit 1
    }

    if (-not (Get-Module -Name "VMware.PowerCLI" -ListAvailable)) {
        Write-Log -Message "Installing VMware PowerCLI" -Level Info
        try {
            Install-Module VMware.PowerCLI -AllowClobber -Force -ErrorAction Stop
        }
        catch {
            Write-Log -Message "Failed to install VMware PowerCLI" -Level Error
            #Exit 1
        }
    }
    Write-Log -Message "Connecting to vSphere" -Level Info
    $Connection = Connect-VIServer -Server $VMwareVCenterIP -Protocol https -User $VMwareUserName -Password $VMwarePassword -Force
    if($connection){
        $Cluster = Get-Cluster -Name $VMwareClusterName
    } else {
        Write-Log -Message "Failed to connect to vSphere" -Level Error
        #Exit 1
    }
        
    Write-Log -Message "Getting Omnissa Base VM UUID" -Level Info
    $var_Omnissa_Base_Vm = Get-VM | where-object { $_.Name -eq $BaseVM }

    if ($null -eq $var_Omnissa_Base_Vm){

        Write-Log -Message "Omnissa Base VM $($BaseVM) Not Found" -Level Error
        #Exit 1

    } else {

        Write-Log -Message "Base VM: $($var_Omnissa_Base_Vm)" -Level Info
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

            Write-Log -Update -Message "Deploying Machine $($i) of $($NumberOfVMs)." -Level Info
            $ResourcePool = (Get-ResourcePool | Where-Object { $_.Name -eq "Resources" }).Name
            $task = New-VM -Name $var_Machine_Name -VM $var_Omnissa_Base_Vm.Name -ResourcePool $ResourcePool -OSCustomizationSpec $CustomizationSpec
            $machineNames.Add($var_Machine_Name)
        }

        Do {
            Write-Log -Update -Message "Waiting for machines to finish deploying" -Level Info
            $TaskCount = (get-task | where-object { ($_.State -like "Running") } | measure-object).count
            Start-Sleep -seconds 5
        }
        Until ($TaskCount -eq 0)

        $i = 1
        foreach ($var_VM in $machineNames) {
            Write-Log -Update -Message "Turning On Machine $($i) of $($NumberOfVMs)." -Level Info
            Start-VM -VM $var_VM -confirm:$false
            $i++
        }

        $machineCount = $machineNames | Measure-Object
        Do {
            Write-Log -Update -Message "Waiting for machines to power on" -Level Info
            $VMsOn = (get-vm | where-object { ($_.Name -like "$($var_Naming_Convention_Base)*") -and ($_.PowerState -eq "PoweredOn") } | measure-object).count
            Start-Sleep -seconds 5
        }
        Until ($VMsOn -eq $machineCount.Count)

        Write-Log -Message "Checking All VMs have a valid IP Address - Please wait" -Level Info
        do {
            $var_Valid_Ips = $false
            Write-Log -Update -Message "Still waiting for valid IPs on all the VMs - Please wait" -Level Info
            foreach ($var_VM in $machineNames) {
                $var_VM_Details = Get-VM -Name $var_VM | Select Name,VMHost, @{N="IPAddress";E={@($_.guest.IPAddress -join '|')}}
                try {
                    $var_VM_IP = $var_VM_Details.IPAddress
                    if([string]::IsNullOrEmpty($var_VM_IP) -Or $var_VM_IP.StartsWith("169.254")) {
                        $var_Valid_Ips = $false
                    } else {
                        $var_Valid_Ips = $true
                    }
                } catch {
                    $var_Valid_Ips = $false
                }
            }
            Write-Log -Update -Message "Still waiting for valid IPs on all the VMs - Please wait" -Level Info
            Start-Sleep -Seconds 5
        } While ($var_Valid_Ips -eq $false)
        Write-Log -Message "IP Addresses Validated - Continuing" -Level Info

        Write-Log -Message "Checking All VMs have a valid WinRM Connection" -Level Info
        do {
            $var_Valid_WinRM = $false
            Write-Log -Update -Message "Still waiting for all VMs to have a valid WinRM Connection - Please wait" -Level Info
            foreach ($var_VM in $machineNames) {
                $var_VM_Details = Get-VM -Name $var_VM | Select Name,VMHost, @{N="IPAddress";E={@($_.guest.IPAddress -join '|')}}
                try {
                    $var_VM_IP = $var_VM_Details.IPAddress
                    if ($var_VM_IP.Contains("|")) { 
                        $Data = $var_VM_IP.Split("|")
                        $var_VM_IP = $Data[0]
                    }
                    if([string]::IsNullOrEmpty($var_VM_IP) -Or $var_VM_IP.StartsWith("169.254")) {
                        $var_Valid_WinRM = $false
                    } else {
                        $port = 5985
                        $socket = New-Object System.Net.Sockets.TcpClient
                        $connection = $socket.BeginConnect("$($var_VM_IP)", $port, $null, $null)
                        $timeout = 1000
                        $wait = $connection.AsyncWaitHandle.WaitOne($timeout, $false)
                        if ($wait -and $socket.Connected) {
                            $var_Valid_WinRM = $true
                        } else {
                            $var_Valid_WinRM = $false
                        }
                        $socket.Close()
                    }
                } catch {
                    $var_Valid_WinRM = $false
                }
            }
            Write-Log -Update -Message "Still waiting for all VMs to have a valid WinRM Connection - Please wait" -Level Info
            Start-Sleep -Seconds 5
        } While ($var_Valid_WinRM -eq $false)
        Write-Log -Message "WinRM Validated - Continuing" -Level Info

        Write-Log -Message "Pausing 5 minutes to let VMs settle down" -Level Info
        Start-Sleep -Seconds 300

        Write-Log -Message "Building Ansible Inventory List" -Level Info
        $var_Inventory_List = ""
        foreach ($var_VM in $machineNames) {
            $var_VM_Details = Get-VM -Name $var_VM | Select Name,VMHost, @{N="IPAddress";E={@($_.guest.IPAddress -join '|')}}
            $var_VM_IP = $var_VM_Details.IPAddress
            if ($var_VM_IP.Contains("|")) { 
                $Data = $var_VM_IP.Split("|")
                $var_VM_IP = $Data[0]
            }
            $var_Inventory_List += "$($var_VM_IP),"
        }
        $var_Inventory_List_Cleaned = $var_Inventory_List.Substring(0,$var_Inventory_List.Length - 1)

        Write-Log -Message "Running Optimizations" -Level Info
        $Playbook = $RootPath + "omnissa_manual_pool_post_deployment.yml"
        $command = "ansible-playbook"
        $arguments = "-f 20 -i " + $var_Inventory_List_Cleaned + ", " + $playbook
        start-process -filepath $command -argumentlist $arguments -passthru -wait 
        
        return $machineNames

    }
}

