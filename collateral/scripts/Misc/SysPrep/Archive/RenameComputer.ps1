<#
    
Copyright © 2015 Citrix Systems, Inc. All rights reserved.

.SYNOPSIS
Rename the computer.

.DESCRIPTION
THis script will rename the computer, automatically adjust the name to avoid clashes.
If there are multiple instances to be created the script will generate ComputerName-1 ComputerName-2  of ech instance etc.
If there is only one instance the ComputerName will be used "as is"

.PARAMETER ComputerName
Name to assign to the computer. 

#>
Param (
    [Parameter(Mandatory=$true)]
    [string]$ComputerName
)

# Get content of scalex.extra file as a hash, fail gracefully (return empty hash) if file does not exist
#function Get-ScaleX.Extra {
#    $extra = @{}
#    $xtraFile = "../../scalex.extra"
#    if (Test-Path $xtraFile) {
#        Get-Content -Path $xtraFile | ForEach-Object {if ($_ -match "(.*)=(.*)") { $extra[$matches[1]]=$matches[2]; }}
#    }
#    return $extra
#}

# Adjust the computer name if this is a multiple server deployment to avoid name clashes
function Adjust-ComputerName {
    Param ( [string]$ComputerName )
#    $extra = Get-ScaleX.Extra
    $index = $extra["index"]   
    $instanceCount = $extra["instanceCount"]
     if ((-not [String]::IsNullOrEmpty($index)) -and ($instanceCount -gt 1)) {
        $ComputerName = "${ComputerName}-$index"
    }
    return $ComputerName
}

$ErrorActionPreference = "Stop"

try {
    $ComputerName = Adjust-ComputerName $ComputerName    
    $result = 0
    $computer = Get-WmiObject Win32_ComputerSystem
    if ($computer.Name.ToLower() -ne $ComputerName.ToLower()) {
        $computer.rename($ComputerName) | Out-Null
        $result = $LastExitCode
    }
    $ComputerName
    exit $result
} catch {
    $error[0]
    exit 1
}