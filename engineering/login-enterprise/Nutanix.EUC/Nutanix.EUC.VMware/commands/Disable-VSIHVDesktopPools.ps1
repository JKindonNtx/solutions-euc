function Disable-VSIHVDesktopPools {
    param(
        [array]$ExcludePools,
        [string]$IncludePools = "*"
    )

    Write-Log -Message "Disabling all pools with name $IncludePools except $ExcludePools" -Level Info
    
    Foreach ($Pool in (Get-HVPool -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true | Where-Object { $_.Base.Name -like $IncludePools })) {
        if (($null -eq $ExcludePools) -or (-not ($ExcludePools.Contains($Pool.Base.Name)))) {
            if ($Pool.type -eq "RDS") {
                Set-HVPool -Disable -PoolName $Pool.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
            }
            else {
                Set-HVPool -Stop -PoolName $Pool.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
                Set-HVPool -Disable -PoolName $Pool.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
            }
            
            Write-Log -Message "Removing all machines for pool $($Pool.base.Name)" -Level Info
            $MachineNames = Get-HVMachine -PoolName $Pool.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true | ForEach-Object { $_.base | Select-Object -expandproperty Name }
            $MachineCount = ($MachineNames | Measure-Object).Count
            if ($MachineCount -gt 0) {
                while ($true) {
                    $Sessions = Get-HVLocalSession | Where-Object { $MachineNames.Contains($_.NamesData.MachineOrRDSServerName) }
                    if ($null -ne $Sessions) {
                        $MachinesWithSessions = $Sessions | ForEach-Object { $_.NamesData | Select-Object -ExpandProperty MachineOrRDSServerName }
                        VMware.VimAutomation.Core\Get-VM -Name $MachinesWithSessions -Server $global:VSIHV_vCenter | VMware.VimAutomation.Core\Restart-VM -Confirm:$false -Server $global:VSIHV_vCenter | Out-Null
                        Start-Sleep -Seconds 30
                    }
                    else {
                        break
                    }
                }

                Remove-HVMachine -MachineNames $MachineNames -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true -Confirm:$false -DeleteFromDisk | Out-Null

                while ($true) {
                    $Machines = $null
                    $Machines = Get-HVMachine -PoolName $Pool.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
                    $MachineCount = ($Machines | Measure-Object).Count
                    
                    if ($MachineCount -eq 0 ) { 
                        break 
                    }
                    else {
                        Write-Log -Update -Message "Still $MachineCount machines in the system" -Level Info
                        $errormachines = $machines | Where-Object { $_.base.BasicState -eq "ERROR" }
                        foreach ($errormachine in $errormachines | select-object -Last 3) {
                            Remove-HVMachine -MachineNames $errormachine.Base.Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true -Confirm:$false -DeleteFromDisk | Out-Null
                        }
                    
                        Start-Sleep -Seconds 60
                    }
                }
                #Write-Log ""
            }
        }
        
    }
}