function Remove-VSIHVDesktopPool {
    param($Name)
    $Pool = Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true
    if ($null -eq $Pool) {
        return
    }
    Write-Log "Removing DesktopPool $Name"
    if ($Pool.Type -ne "RDS") {
        Remove-HVPool -hvServer $global:VSIHV_ConnectionServer -PoolName $Name -DeleteFromDisk -Confirm:$false -TerminateSession -SuppressInfo $true
        Write-Log "Waiting for DesktopPool $Name to be removed"
        while ($null -ne (Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true)) {
            Start-Sleep -Seconds 30
        }
    } else {
        Remove-HVPool -hvServer $global:VSIHV_ConnectionServer -PoolName $Name -TerminateSession -SuppressInfo $true
        Write-Log "Waiting for DesktopPool $Name to be removed"
        while ($null -ne (Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SuppressInfo $true)) {
            Start-Sleep -Seconds 30
        }
        $Farm = Get-HVFarm -hvServer $Global:VSIHV_ConnectionServer -FarmName "F_$Name"
        if ($null -ne $Farm) {
            Remove-HVFarm -FarmName "F_$Name"
        }
        Write-Log "Waiting for Farm F_$Name to be removed"
        while ($null -ne (Get-HVFarm -FarmName "F_$Name" -HvServer $Global:VSIHV_ConnectionServer)) {
            Start-Sleep -Seconds 30
        }
    }
    
   
}