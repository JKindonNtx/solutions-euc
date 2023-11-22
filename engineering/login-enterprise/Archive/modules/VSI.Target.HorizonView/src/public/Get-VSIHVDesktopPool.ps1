function Get-VSIHVDesktopPools {
    param(
        $Name
    )
    Get-HVPool -PoolName $Name -HvServer $Global:VSIHV_ConnectionServer -SupressInfo $true
}