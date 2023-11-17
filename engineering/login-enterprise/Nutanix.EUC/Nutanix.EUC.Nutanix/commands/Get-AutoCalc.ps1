function Get-AutoCalc {

    #region Handle AutoCalc
    If ($VSI_Target_AutocalcVMs) {
        If ($VSI_Target_Max) {
            $VSI_VSImax = 1
        }
        Else { $VSI_VSImax = 0.8 }
        $TotalCores = $NTNXInfra.Testinfra.CPUCores * $VSI_Target_NodeCount
        $TotalGHz = $TotalCores * $NTNXInfra.Testinfra.CPUSpeed * 1000
        $vCPUsperVM = $VSI_Target_NumCPUs * $VSI_Target_NumCores
        $GHzperVM = 600 * $WLmultiplier
        # Set the vCPU multiplier. This affects the number of VMs per node.
        $vCPUMultiplier = "1.$vCPUsperVM"
        #$TotalMem = [Math]::Round($NTNXInfra.Testinfra.MemoryGB * 0.92, 0, [MidpointRounding]::AwayFromZero) * $VSI_Target_NodeCount
        $TotalMem = $VSI_Target_NodeCount * (($($NTNXInfra.Testinfra.MemoryGB) - 32) * 0.94)
        $MemperVM = $VSI_Target_MemoryGB
        if ($($VSI_Target_SessionsSupport.ToLower()) -notin $Validated_OS_Types) {
            Write-Log -Message "OS Type is: $($VSI_Target_SessionsSupport) and is not a valid type for testing. Please check config file" -Level Error
        }
        if ($($VSI_Target_SessionsSupport.ToLower()) -eq "multisession") {
            $VSI_Target_NumberOfVMS = [Math]::Round(($TotalCores - (4 * $VSI_Target_NodeCount)) / $vCPUsperVM * 2, 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            if ($TotalMem -le ($VSI_Target_NumberOfVMS * $MemperVM)) {
                $VSI_Target_NumberOfVMS = [Math]::Round($TotalMem / $MemperVM, 0, [MidpointRounding]::AwayFromZero)
                $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            }
            $RDSHperVM = [Math]::Round(18 / $WLmultiplier, 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_NumberOfSessions = [Math]::Round($VSI_Target_NumberOfVMS * $RDSHperVM * $VSI_VSImax, 0, [MidpointRounding]::AwayFromZero)
        }
        if ($($VSI_Target_SessionsSupport.ToLower()) -eq "singlesession") {
            $VSI_Target_NumberOfVMS = [Math]::Round(($TotalGHz / ($GHzperVM * $vCPUMultiplier) * $VSI_VSImax), 0, [MidpointRounding]::AwayFromZero)
            $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            if ($TotalMem -le ($VSI_Target_NumberOfVMS * $MemperVM)) {
                $VSI_Target_NumberOfVMS = [Math]::Round($TotalMem / $MemperVM, 0, [MidpointRounding]::AwayFromZero)
                $VSI_Target_PowerOnVMs = $VSI_Target_NumberOfVMS
            }
            $VSI_Target_NumberOfSessions = $VSI_Target_NumberOfVMS
        }
        ($NTNXInfra.Target.ImagesToTest | Where-Object { $_.Comment -eq $VSI_Target_Comment }).NumberOfVMs = $VSI_Target_NumberOfVMS
        ($NTNXInfra.Target.ImagesToTest | Where-Object { $_.Comment -eq $VSI_Target_Comment }).PowerOnVMs = $VSI_Target_PowerOnVMs
        ($NTNXInfra.Target.ImagesToTest | Where-Object { $_.Comment -eq $VSI_Target_Comment }).NumberOfSessions = $VSI_Target_NumberOfSessions
        Write-Log -Message "AutoCalc is enabled and the number of VMs is set to $VSI_Target_NumberOfVMS and the number of sessions to $VSI_Target_NumberOfSessions on $VSI_Target_NodeCount Node(s)" -Level Info
    }
    #endregion Handle AutoCalc
    
}