<#
    
Copyright © 2014 Citrix Systems, Inc. All rights reserved.

.SYNOPSIS
Join the specified domain

.DESCRIPTION

#>
Param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,    
    [Parameter(Mandatory=$true)]
    [string]$UserName,  
    [Parameter(Mandatory=$true)]
    [string]$Password
)

$ErrorActionPreference = "Stop"
try {
    if (-not $UserName.Contains('\') -and -not $UserName.Contains('@')) {
        $UserName = "$DomainName\$UserName"
    }
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force 
    $DomainCredentials = New-Object System.Management.Automation.PSCredential $UserName, $securePassword   
    $result = Add-Computer -DomainName $DomainName -Credential $DomainCredentials -PassThru -WarningAction SilentlyContinue
    if (-not $result.HasSucceeded) {
        throw "Domain join failed: $result"
    }
    return "$($result.ComputerName).$DomainName"
} catch {
    $error[0]
    exit 1
}
