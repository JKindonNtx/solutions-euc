function Set-VMWareHostAlignment {

    [CmdletBinding()]

    param (
        [Parameter(Mandatory = $false)][string]$DDC,
        [Parameter(Mandatory = $true)][int32]$MachineCount,
        [Parameter(Mandatory = $true)][int32]$HostCount,
        [Parameter(Mandatory = $true)][string]$VCenter,
        [Parameter(Mandatory = $true)][string]$User,
        [Parameter(Mandatory = $true)][string]$Password,
        [Parameter(Mandatory = $true)][string]$ClusterName,
        [Parameter(Mandatory = $true)][string]$DataCenter,
        [Parameter(Mandatory = $false)][string]$DesktopGroupName,
        [Parameter(Mandatory = $true)][string]$Run,
        [Parameter(Mandatory = $false)][int32]$MaxRecordCount,
        [Parameter(Mandatory = $false)]$OmnissaMachineList
    )

    if ($Run -eq 1) {
        # We will process because this is run one

        #region figure out Machine Count Per Host
        if ([int32]$HostCount -gt $MachineCount) {
            Write-Log -Message "Less VMS than Hosts. Resetting Host count to VM count" -Level Info
            [int32]$HostCount = $MachineCount
        }

        $VMSPerHost = $MachineCount / $HostCount

        # If $VMSPerHost isn't an even number, we need to figure out how to make it so
        if ($VMSPerHost -ne [math]::Floor($VMSPerHost)) {
            Write-Log -Message "There is not an even distribution of VMs to Hosts based on inputs. Resolving differential and organising distribution" -Level Info
            #Start at zero, capture the number of machines we remove from the $MachineCount count in an attempt to get an even distribution.
            $MachinesToAssignPostGrouping = 0
                
            ##-------------------------
            ## Depth 1
            ##-------------------------
            [int32]$MachineCount = ([int32]$MachineCount - 1) # Drop 1 VM out of the total VM count
            $MachinesToAssignPostGrouping ++ # Add the machine that we just removed from the total trying to get an even count
            $VMSPerHost = $MachineCount / $HostCount # reset the VMSPerHost -1 to get to an even

            if ($VMSPerHost -ne [math]::Floor($VMSPerHost)) {
                ##-------------------------
                ## Depth 2
                ##-------------------------
                [int32]$MachineCount = ([int32]$MachineCount - 1) #Drop 1 VM out of the total VM count
                $MachinesToAssignPostGrouping ++ ## Add the machine that we just removed from the total trying to get an even count
                $VMSPerHost = $MachineCount / $HostCount ## reset the VMSPerHost -1 to get to an even
            
                if ($VMSPerHost -ne [math]::Floor($VMSPerHost)) {
                    ##-------------------------
                    ## Depth 3
                    ##-------------------------
                    [int32]$MachineCount = ([int32]$MachineCount - 1) #Drop 1 VM out of the total VM count
                    $MachinesToAssignPostGrouping ++ ## Add the machine that we just removed from the total trying to get an even count
                    $VMSPerHost = $MachineCount / $HostCount ## reset the VMSPerHost -1 to get to an even
            
                    if ($VMSPerHost -ne [math]::Floor($VMSPerHost)) {
                        ##-------------------------
                        ## Depth 4
                        ##-------------------------
                        [int32]$MachineCount = ([int32]$MachineCount - 1) #Drop 1 VM out of the total VM count
                        $MachinesToAssignPostGrouping ++ ## Add the machine that we just removed from the total trying to get an even count
                        $VMSPerHost = $MachineCount / $HostCount ## reset the VMSPerHost -1 to get to an even
            
                        if ($VMSPerHost -ne [math]::Floor($VMSPerHost)) {
                            ##-------------------------
                            ## Depth 5
                            ##-------------------------
                            [int32]$MachineCount = ([int32]$MachineCount - 1) #Drop 1 VM out of the total VM count
                            $MachinesToAssignPostGrouping ++ ## Add the machine that we just removed from the total trying to get an even count
                            $VMSPerHost = $MachineCount / $HostCount ## reset the VMSPerHost -1 to get to an even
            
                            if ($VMSPerHost -ne [math]::Floor($VMSPerHost)) {
                                ##-------------------------
                                ## Depth 6
                                ##-------------------------
                                [int32]$MachineCount = ([int32]$MachineCount - 1) #Drop 1 VM out of the total VM count
                                $MachinesToAssignPostGrouping ++ ## Add the machine that we just removed from the total trying to get an even count
                                $VMSPerHost = $MachineCount / $HostCount ## reset the VMSPerHost -1 to get to an even
            
                                if ($VMSPerHost -ne [math]::Floor($VMSPerHost)) {
                                    ##-------------------------
                                    ## Depth 7 - This should be the final depth on an 8 node limit, everything else should be a whole number
                                    ##-------------------------
                                    [int32]$MachineCount = ([int32]$MachineCount - 1) #Drop 1 VM out of the total VM count
                                    $MachinesToAssignPostGrouping ++ ## Add the machine that we just removed from the total trying to get an even count
                                    $VMSPerHost = $MachineCount / $HostCount ## reset the VMSPerHost -1 to get to an even
                                }
                                else {
                                    $VMSPerHost = $VMSPerHost
                                }
            
                            }
                            else {
                                $VMSPerHost = $VMSPerHost
                            }
            
                        }
                        else {
                            $VMSPerHost = $VMSPerHost
                        }
            
                    }
                    else {
                        $VMSPerHost = $VMSPerHost
                    }
            
                }
                else {
                    $VMSPerHost = $VMSPerHost
                }
            }
            else {
                $VMSPerHost = $VMSPerHost
            }

        }
        else {
            $VMSPerHost = $VMSPerHost
            $MachinesToAssignPostGrouping = 0
        }

        # Report output on how many machines will be realigned across hosts
        Write-Log -Message "There is an even distribution of $($VMSPerHost) VMs per host" -Level Info
        if ($MachinesToAssignPostGrouping -gt 0) {
            Write-Log -Message "There are $($MachinesToAssignPostGrouping) remaining VMs to distribute" -Level Info
        }

        # Set the initial distribution value based on the above logic
        $MachineCountPerHost = $VMSPerHost
        #endregion figure out Machine Count Per Host
            
        #region learn about vmware hosts
        try {
            $Module = "VMware.VimAutomation.Core"
            Write-Log -Message "Importing Module: $($Module)" -Level Info
            Import-Module -Name $Module -ErrorAction Stop
            # Connect to vCenter
            Write-Log -Message "Connecting to vCenter: $($VCenter)" -Level Info
            $VIServerConnection = Connect-VIServer -Server $VCenter -Port "443" -Protocol "https" -User $User -Password $Password -Force -ErrorAction Stop
            # Get Cluster Details
            Write-Log -Message "Getting Cluster details for Cluster: $($ClusterName) in Datacenter: $($DataCenter)" -Level Info
            $Cluster = Get-Cluster -Server $VCenter -Name $ClusterName -Location $DataCenter -ErrorAction Stop
            # Get Host Details
            Write-Log -Message "Getting Host Details" -Level Info
            $VmwareHosts = Get-VMHost -Location $Cluster.Name -ErrorAction Stop
            Write-Log -Message "Retrieved Cluster details for Cluster $($Cluster.Name) and $(($VmwareHosts | Measure-Object).count) Host Details" -Level Info
        }
        catch {
            Write-Log -Message $_ -Level Error
            # What should we do here??
        }
            
        if (-not [string]::IsNullOrEmpty($VmwareHosts)) {
            $VmwareHosts = $VmwareHosts | Sort-Object -Property name
            $VmwareHostsCount = ($VmwareHosts | Measure-Object).count
            if ($VmwareHostsCount -lt $HostCount) {
                Write-Log -Message "There are less hosts in the cluster than specifid for the test. Specfied: $($HostCount) but only found: $($VmwareHostsCount). Ignoring Alignment" -Level Warn
                $CanProcessAlignment = $false
            }
            else {
                Write-Log -Message "There are $($VmwareHostsCount) Nodes found in the cluster. Test is configured to use $($HostCount) Nodes" -Level Info
                $CanProcessAlignment = $true
            }
        }
        else {
            # Failed to retrieve VMware host detail
            Write-Log -Message "Failed to retrieve VMware host detail" -Level Warn
            Write-Log -Message $_ -Level Warn
            Exit 1
        }
        #endregion learn about vmware hosts

        if ($CanProcessAlignment -eq $true) {
            #region learn about Citrix VMs
            if ($DDC -eq "Omnissa") {
                $MachineList = [System.Collections.ArrayList]@()
                foreach($VM in $OmnissaMachineList){
                    $VmFqdn = $VM.dns_name
                    $VmSplit = $VmFqdn.Split(".")
                    $VmNetbiosName = $VmSplit[0]
                    $MachineList.Add($VmNetbiosName)
                }
                Write-Log -Message "Retrieved $(($OmnissaMachineList | Measure-Object).Count) Machines from Omnissa" -Level Info
            } else {
                Write-Log -Message "Retrieving list of machines from Delivery Group" -Level Info
                $MachineList = Get-CitrixBrokerMachineList -DDC $DDC -DesktopGroupName $DesktopGroupName -MaxRecordCount $MaxRecordCount
                $MachineList = $MachineList | Sort-Object HostedMachineName
                if ($MachineList) {
                    Write-Log -Message "Retrieved $(($MachineList | Measure-Object).Count) Machines from Citrix" -Level Info
                }
                else {
                    Write-Log -Message "No Machines Retrieved" -Level Warn
                    Exit 1
                }
            }
            #endregion learn about Citrix VMs

            #region sort VM distribution
            $MachineList_Host_1 = $null
            $MachineList_Host_2 = $null
            $MachineList_Host_3 = $null
            $MachineList_Host_4 = $null
            $MachineList_Host_5 = $null
            $MachineList_Host_6 = $null
            $MachineList_Host_7 = $null
            $MachineList_Host_8 = $null

            Write-Log -Message "Sorting machines into batches for Affintity" -Level Info
            if ($DDC -eq "Omnissa") {
                $MachineList_Host_1 = ($MachineList | Select-Object -First $MachineCountPerHost)
                if ($HostCount -gt 1) { $MachineList_Host_2 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip $MachineCountPerHost) }
                if ($HostCount -gt 2) { $MachineList_Host_3 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 2)) }
                if ($HostCount -gt 3) { $MachineList_Host_4 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 3)) }
                if ($HostCount -gt 4) { $MachineList_Host_5 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 4)) }
                if ($HostCount -gt 5) { $MachineList_Host_6 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 5)) }
                if ($HostCount -gt 6) { $MachineList_Host_7 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 6)) }
                if ($HostCount -gt 7) { $MachineList_Host_8 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 7)) }
            } else {
                $MachineList_Host_1 = ($MachineList | Select-Object -First $MachineCountPerHost).HostedMachineName
                if ($HostCount -gt 1) { $MachineList_Host_2 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip $MachineCountPerHost).HostedMachineName }
                if ($HostCount -gt 2) { $MachineList_Host_3 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 2)).HostedMachineName }
                if ($HostCount -gt 3) { $MachineList_Host_4 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 3)).HostedMachineName }
                if ($HostCount -gt 4) { $MachineList_Host_5 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 4)).HostedMachineName }
                if ($HostCount -gt 5) { $MachineList_Host_6 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 5)).HostedMachineName }
                if ($HostCount -gt 6) { $MachineList_Host_7 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 6)).HostedMachineName }
                if ($HostCount -gt 7) { $MachineList_Host_8 = ($MachineList | Select-Object -First $MachineCountPerHost -Skip ($MachineCountPerHost * 7)).HostedMachineName }
            } 
            #endregion sort VM distribution

            #region deal with orphaned VM distribution
            if ($MachinesToAssignPostGrouping -gt 1) {

                # We have already sorted the even list by -First, so grab the -Last $MachinesToAssignPostGrouping count to find what is left, then distribute them across nodes starting from node 1
                $MachineList_Host_Orphaned = ($MachineList | Select-Object -Last $MachinesToAssignPostGrouping).HostedMachineName

                if (($MachineList_Host_Orphaned | Measure-Object).Count -eq 1) {
                    $MachineList_Host_1 += $MachineList_Host_Orphaned[0]
                }
                if (($MachineList_Host_Orphaned | Measure-Object).Count -eq 2) {
                    $MachineList_Host_1 += $MachineList_Host_Orphaned[0]
                    $MachineList_Host_2 += $MachineList_Host_Orphaned[1]
                }
                if (($MachineList_Host_Orphaned | Measure-Object).Count -eq 3) {
                    $MachineList_Host_1 += $MachineList_Host_Orphaned[0]
                    $MachineList_Host_2 += $MachineList_Host_Orphaned[1]
                    $MachineList_Host_3 += $MachineList_Host_Orphaned[2]
                }
                if (($MachineList_Host_Orphaned | Measure-Object).Count -eq 4) {
                    $MachineList_Host_1 += $MachineList_Host_Orphaned[0]
                    $MachineList_Host_2 += $MachineList_Host_Orphaned[1]
                    $MachineList_Host_3 += $MachineList_Host_Orphaned[2]
                    $MachineList_Host_4 += $MachineList_Host_Orphaned[3]
                }
                if (($MachineList_Host_Orphaned | Measure-Object).Count -eq 5) {
                    $MachineList_Host_1 += $MachineList_Host_Orphaned[0]
                    $MachineList_Host_2 += $MachineList_Host_Orphaned[1]
                    $MachineList_Host_3 += $MachineList_Host_Orphaned[2]
                    $MachineList_Host_4 += $MachineList_Host_Orphaned[3]
                    $MachineList_Host_5 += $MachineList_Host_Orphaned[4]
                }
                if (($MachineList_Host_Orphaned | Measure-Object).Count -eq 6) {
                    $MachineList_Host_1 += $MachineList_Host_Orphaned[0]
                    $MachineList_Host_2 += $MachineList_Host_Orphaned[1]
                    $MachineList_Host_3 += $MachineList_Host_Orphaned[2]
                    $MachineList_Host_4 += $MachineList_Host_Orphaned[3]
                    $MachineList_Host_5 += $MachineList_Host_Orphaned[4]
                    $MachineList_Host_6 += $MachineList_Host_Orphaned[5]
                }
                if (($MachineList_Host_Orphaned | Measure-Object).Count -eq 7) {
                    $MachineList_Host_1 += $MachineList_Host_Orphaned[0]
                    $MachineList_Host_2 += $MachineList_Host_Orphaned[1]
                    $MachineList_Host_3 += $MachineList_Host_Orphaned[2]
                    $MachineList_Host_4 += $MachineList_Host_Orphaned[3]
                    $MachineList_Host_5 += $MachineList_Host_Orphaned[4]
                    $MachineList_Host_6 += $MachineList_Host_Orphaned[5]
                    $MachineList_Host_7 += $MachineList_Host_Orphaned[6]
                }
            }
            #endregion deal with orphaned VM distribution

            #region Sort out the number of hosts we are going to be dealing with for reporting output
            $HostCount_1_Node = (1, 2, 3, 4, 5, 6, 7, 8)   # Host 1 will always be in play
            $HostCount_2_Node = (2, 3, 4, 5, 6, 7, 8)     # Host 2 will be in a 2, 3, 4, 5, 6, 7, 8 Node test
            $HostCount_3_Node = (3, 4, 5, 6, 7, 8)       # Host 3 will be in a 3, 4, 5, 6, 7, 8 Node test
            $HostCount_4_Node = (4, 5, 6, 7, 8)         # Host 4 will be in a 4, 5, 6, 7, 8 Node test
            $HostCount_5_Node = (5, 6, 7, 8)           # Host 5 will be in a 5, 6, 7, 8 Node test
            $HostCount_6_Node = (6, 7, 8)             # Host 6 will be in a 6, 7, 8 Node test
            $HostCount_7_Node = (7, 8)               # Host 7 will be in a 7, 8 Node test
            $HostCount_8_Node = (8)                 # Host 8 will ony be in an 8 node test

            if ($HostCount -in $HostCount_1_Node) { Write-Log -Message "Host 1: $($VmwareHosts[0].name) is included with VM count: $(($MachineList_Host_1 | Measure-Object).Count)" -Level Info }
            if ($HostCount -in $HostCount_2_Node) { Write-Log -Message "Host 2: $($VmwareHosts[1].name) is included with VM count: $(($MachineList_Host_2 | Measure-Object).Count)" -Level Info }
            if ($HostCount -in $HostCount_3_Node) { Write-Log -Message "Host 3: $($VmwareHosts[2].name) is included with VM count: $(($MachineList_Host_3 | Measure-Object).Count)" -Level Info }
            if ($HostCount -in $HostCount_4_Node) { Write-Log -Message "Host 4: $($VmwareHosts[3].name) is included with VM count: $(($MachineList_Host_4 | Measure-Object).Count)" -Level Info }
            if ($HostCount -in $HostCount_5_Node) { Write-Log -Message "Host 5: $($VmwareHosts[4].name) is included with VM count: $(($MachineList_Host_5 | Measure-Object).Count)" -Level Info }
            if ($HostCount -in $HostCount_6_Node) { Write-Log -Message "Host 6: $($VmwareHosts[5].name) is included with VM count: $(($MachineList_Host_6 | Measure-Object).Count)" -Level Info }
            if ($HostCount -in $HostCount_7_Node) { Write-Log -Message "Host 7: $($VmwareHosts[6].name) is included with VM count: $(($MachineList_Host_7 | Measure-Object).Count)" -Level Info }
            if ($HostCount -in $HostCount_8_Node) { Write-Log -Message "Host 8: $($VmwareHosts[7].name) is included with VM count: $(($MachineList_Host_8 | Measure-Object).Count)" -Level Info }
            #endregion Sort out the number of hosts we are going to be dealing with for reporting output

            #region Process the alignment

            #region Validate Host Groups
            Write-Log -Message "Validating DRS Host Groups" -Level Info

            # Our hosts start at item 0 in the array

            #----------------------------------------------------------
            # Process Host 1
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_1)) {
                $VMWareHost = $VmwareHosts[0].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_1
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #----------------------------------------------------------
            # Process Host 2
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_2)) {
                $VMWareHost = $VmwareHosts[1].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_2
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #----------------------------------------------------------
            # Process Host 3
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_3)) {
                $VMWareHost = $VmwareHosts[2].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_3
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #----------------------------------------------------------
            # Process Host 4
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_4)) {
                $VMWareHost = $VmwareHosts[3].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_4
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #----------------------------------------------------------
            # Process Host 5
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_5)) {
                $VMWareHost = $VmwareHosts[4].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_5
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #----------------------------------------------------------
            # Process Host 6
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_6)) {
                $VMWareHost = $VmwareHosts[5].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_6
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #----------------------------------------------------------
            # Process Host 7
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_7)) {
                $VMWareHost = $VmwareHosts[6].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_7
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #----------------------------------------------------------
            # Process Host 8
            #----------------------------------------------------------
            if (-not [string]::IsNullOrEmpty($MachineList_Host_8)) {
                $VMWareHost = $VmwareHosts[7].name
                $HostIP = (Get-VMHostNetworkAdapter -VMHost $VMWareHost | Where-Object {$_.Name -eq "vmk0"}).IP
                $HostGroupName = "HostGroup_$($HostIP)"
                $HostMachineList = $MachineList_Host_8
                $VMGroupName = "VMGroup_$($HostIP)"

                Set-VMWareClusterHostGroup -Cluster $Cluster.Name -HostGroupName $HostGroupName -VMHost $VMWareHost

                # Validate VM Group
                Set-VMWareClusterVMGroup -Cluster $Cluster.Name -VMGroupName $VMGroupName -VMList $HostMachineList

                # Validate VM Group to Host Rule
                Set-VMwareClusterDRSHostRule -Cluster $Cluster.Name -VMGroupName $VMGroupName -HostGroupName $HostGroupName
            }
            #endregion Validate Host Groups

            #endregion Process the alignment
        }

    }
    else {
        #We will not process because this has already been completed on run 1
        Write-Log -Message "We will not process affinity jobs as they have been completed in run1" -Level Info
    }

    return $True

}