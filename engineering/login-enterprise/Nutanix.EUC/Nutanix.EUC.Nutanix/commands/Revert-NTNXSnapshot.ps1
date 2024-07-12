function Revert-NTNXSnapshot {

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVM,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMAdmin,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$TargetCVMPassword,
        [Parameter(ValuefromPipelineByPropertyName = $true, Mandatory = $false)][String]$VmUuid
    )


    $Snapshot = Invoke-PublicApiMethodNTNX -Method "GET" -Path "snapshots/?vm_uuid=$($VMUUID)" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop

    $Name = $Snapshot.entities.snapshot_name
    $SnapUUUID = $Snapshot.entities.uuid

    $Payload = "{ `
      ""snapshot_uuid"":""" + $SnapUUUID + """ `
    }"

    $RevertTask = Invoke-PublicApiMethodNTNX -Method "POST" -Path "vms/$($VmUuid)/restore" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -Body $Payload -ErrorAction Stop

    $RevertTaskID = $RevertTask.task_uuid

    Do {
        $VMtaskinfo = Invoke-PublicApiMethodNTNX -Method "GET" -Path "tasks/$($RevertTaskID)" -TargetCVM $TargetCVM -TargetCVMAdmin $TargetCVMAdmin -TargetCVMPassword $TargetCVMPassword -ErrorAction Stop
        $VMtaskstatus = $VMtaskinfo.percentage_complete
        If ( $VMtaskstatus -ne 100) {
            Start-Sleep -Seconds 1
        }
    }
    Until ($VMtaskstatus -eq 100)
}