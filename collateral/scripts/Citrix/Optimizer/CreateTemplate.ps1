function Get-RegistryType {

    [CmdletBinding()]

    Param (
        [Parameter(
            ValuefromPipelineByPropertyName = $true,mandatory=$false
        )]
        $Type
    )

    if($null -eq $type){ $Type = "REG_SZ" }
    switch ($Type)
    {
        "REG_DWORD" {$Return = "Dword"}
        "REG_SZ" {$Return = "String"}
        "REG_MULTI_SZ" {$Return = "MultiString"}
        "REG_BINARY" {$Return = "Binary"}
    }

    Return $Return

}

function Get-DefaultUserKey {

    [CmdletBinding()]

    Param (
        [Parameter(
            ValuefromPipelineByPropertyName = $true,mandatory=$false
        )]
        $KeyName
    )

    $Return = $KeyName.Replace("HKCU", "HKDU")

    Return $Return

}

# Define Template Name
$TemplateName = 'Nutanix Solutions Architecture EUC.xml'

# Remove and re-import the module
Write-Host "Import Citrix Optimizer Automation"
install-module CitrixOptimizerAutomation -AllowClobber -Force

# Create a new Template
Write-Host "Create a new Citrix Optimizer Template: $($TemplateName)"
$Template = New-CitrixTemplate -Path $TemplateName -DisplayName 'Nutanix Solutions Architecture EUC' -Description 'Citrix Optimizer Template used for the Nutanix Solutions Architecture Team to run Performance Tests' -Author 'Solutions EUC'

# Define Path to exported VMware OSOT
$Path = "VMware_OSOT.xml"

# Read Entire OSOT File
[XML]$OSOT = Get-Content $Path

foreach($TopLevel in $OSOT.sequence.group.group){
    $TopLevelName = $TopLevel.name
    $SubLevelGroups = $TopLevel.group
    foreach($SubLevel in $SubLevelGroups){
        $GroupName = "$($TopLevelName) - $($SubLevel.name)"
        Write-Host "Create a new Group $($GroupName)"
        $Group = New-CitrixTemplateGroup -Path $Template.Path -GroupName $GroupName -GroupDescription $GroupName
        $Section = $Sublevel

        #Loop through the variable
        foreach($object in $Section.step){

            # Get the name and description
            $Name = $Object.name
            $Description = $Object.Description

            # Check if its recommended and enabled by default
            if(($Object.category -eq "recommended") -and ($Object.defaultSelected -eq $true)){
                # Set to process
                $Process = $true
            } else {
                # Set to skip
                $Process = $false
            }
            # Get the action into a variable
            $Action = $Object.action

            # Registry Add Item
            if(($Action.type -eq "Registry") -and ($Action.command -eq "ADD") -and ($Process)){
                $Params = $Action.params
                Write-Host "Add Registry Value: $($Object.name)"
                if($Params.keyName -like "HKCU*"){
                    $Key = Get-DefaultUserKey -KeyName $Params.keyName
                } else {
                    $Key = $Params.keyName
                }
                if($Params.data -eq "<about:blank>"){
                    $Data = " "
                } else {
                    $Data = $Params.data
                }
                $Registry = New-CitrixTemplateRegistry -Path $Template.Path -GroupName $GroupName -EntryName $Object.Name -EntryDescription $Object.Description -ItemName "$($Params.valueName)" -ItemPath "$($Key)" -ItemValue "$($Data)" -ItemType (Get-RegistryType -Type $Params.type)
            }

            # Registry Delete Value
            if(($Action.type -eq "Registry") -and ($Action.command -eq "DELETEVALUE") -and ($Process)){
                $Params = $Action.params
                Write-Host "Delete Registry Value: $($Object.name)"
                if($Params.keyName -like "HKCU*"){
                    $Key = Get-DefaultUserKey -KeyName $Params.keyName
                } else {
                    $Key = $Params.keyName
                }
                $Registry = New-CitrixTemplateRegistry -Path $Template.Path -GroupName $GroupName -EntryName $Object.Name -EntryDescription $Object.Description -ItemName "$($Params.valueName)" -ItemPath "$($Key)" -DeleteValue
            }

            # Disable Scheduled Tasks
            if(($Action.type -eq "SchTasks") -and ($Process)){
                $Params = $Action.params
                Write-Host "Add Scheduled Task: $($Object.name)"
                $Task = New-CitrixTemplateTask -Path $Template.Path -GroupName $GroupName -TaskName $Object.Name -TaskPath $Params.taskName -TaskDescription $Object.Description -State "Disabled" 
            }

            # Disable Service
            if(($Action.type -eq "Service") -and ($Process)){
                $Params = $Action.params
                Write-Host "Add Service: $($Object.name)"
                $Service = New-CitrixTemplateService -Path $Template.Path -EntryName $Object.Name -ServiceName $Params.serviceName -ServiceDescription $Object.Description -GroupName $GroupName -State "Disabled"
            }   
        }  
    }
}

$Group = New-CitrixTemplateGroup -Path $Template.Path -GroupName "Finalize" -GroupDescription "Final Tasks to complete before image seal"
$ScriptedAction = New-CitrixTemplateScript -Path $Template.Path -GroupName "Finalize" -EntryName "Clear Scheduled Tasks" -EntryDescription "Clear out any remaining Scheduled Tasks" -ScriptFile "Script_ClearScheduledTasks.ps1"
$ScriptedAction = New-CitrixTemplateScript -Path $Template.Path -GroupName "Finalize" -EntryName "Remove AppX Packages" -EntryDescription "Removes the AppX Packages for All Users" -ScriptFile "Script_RemoveAppxPackages.ps1"
$ScriptedAction = New-CitrixTemplateScript -Path $Template.Path -GroupName "Finalize" -EntryName "Set Power Plan" -EntryDescription "Sets the Power Plan to High Performance" -ScriptFile "Script_SetPowerPlan.ps1"
$ScriptedAction = New-CitrixTemplateScript -Path $Template.Path -GroupName "Finalize" -EntryName "Run NGEN Update" -EntryDescription "Runs the .NET NGEN Update Routines" -ScriptFile "Script_NGENUpdate.ps1"
$ScriptedAction = New-CitrixTemplateScript -Path $Template.Path -GroupName "Finalize" -EntryName "Clear Event Logs" -EntryDescription "Clears the System Event Logs" -ScriptFile "Script_ClearEventLogs.ps1"  

$Registry = New-CitrixTemplateRegistry -Path $Template.Path -GroupName "Finalize" -EntryName "Disable Show Dynamic Content" -EntryDescription "Diable the Dynamic Content in the Search Box" -ItemName "ShowDynamicContent" -ItemPath "HKDU\Software\Microsoft\Windows\CurrentVersion\Feeds\DSB" -ItemValue "0" -ItemType "Dword"
$Registry = New-CitrixTemplateRegistry -Path $Template.Path -GroupName "Finalize" -EntryName "Disable Dynamic Search Box" -EntryDescription "Diable the Dynamic Search Box" -ItemName "IsDynamicSearchBoxEnabled" -ItemPath "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -ItemValue "0" -ItemType "Dword"
