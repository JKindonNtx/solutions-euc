#Requires -Version 3.0
#This File is in Unicode format.  Do not edit in an ASCII editor.

#region Support

<#
.SYNOPSIS
    Creates a complete inventory of a Nutanix configuration using Microsoft Word 2010 or 2013.
.DESCRIPTION
    Creates a complete inventory of a Nutanix Cluster configuration using Microsoft Word and PowerShell.
.PARAMETER UserName
    User name to use for the Cover Page and Footer.
    Default value is contained in $env:username
    This parameter has an alias of UN.
"
.INPUTS
    None.  You cannot pipe objects to this script.
.OUTPUTS
    No objects are output from this script.  
    This script creates a Word, PDF, Formatted Text or HTML document.
.NOTES
    NAME: Nutanix_Documentation_Script_v1.ps1
    VERSION: 1.0
    AUTHOR: Kees Baggerman with help from Carl Webster, Michael B. Smith, Iain Brighton, Jeff Wouters, Barry Schiffer
    LASTEDIT: January 20, 2015
#>

#endregion Support

#region script template
#thanks to @jeffwouters and Michael B. Smith for helping me with these parameters
[CmdletBinding(SupportsShouldProcess = $False, ConfirmImpact = "None" )]

Param(

    # Nutanix cluster IP address
    [Parameter(Mandatory = $true)]
    [Alias('IP')] [string] $nxIP,
     
    # Nutanix cluster username
    [Parameter(Mandatory = $true)]
    [Alias('User')] [string] $nxUser,
    # Nutanix cluster password
    [Parameter(Mandatory = $true)]
    [Alias('Password')] [string] $nxPassword
   
)
 
#kees@nutanix.com
#@kbaggerman on Twitter
#http://blog.myvirtualvision.com
#Created on Januari 20, 2015

Set-StrictMode -Version 2


#region Loading cmdlets

# Copyright (c) 2014 Nutanix Inc. All rights reserved.
#
# Author : isha.singhal@nutanix.com
#
# Description: Script to Import all the cmdlets to powershell.

Param (
# The prefix to be added to all Nutanix cmdlet nouns to resolve name clashes
# with cmdlets from other libraries.
[Parameter(Mandatory = $False)]
[string] $nounPrefix = "NTNX"
)

# Get the path of the directory where current script is located.
# This is needed to get the path of Modules directory
# Modules folder has all the built DLLs.
# Each DLL in the module folder is placed inside a folder. This folder has the
# same name as the name of the DLL. This is structure in which powershell
# looks for all the DLLs.
$PSScriptLocation = Split-Path -Parent -Path $MyInvocation.MyCommand.Path

# Get the location of the Modules folder of the compiled DLLs. The modules
# folder lies in powershell\import_modules. Thus to get the path of
# modules folder we need two level of "..".
$dllPath = $PSScriptLocation + "\..\..\Modules"

# Get the installutil directory at runtime according to the installed .NET
# framework. installutil is used to register the snapin permanently on the
# user's system.
$installUtilDir = $( `
    [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())
$installUtilDir += "\installutil"
Set-Alias installutil  $installUtilDir
installUtil $dllPath\NutanixCmdletsPSSnapin.dll >> ""

# Check if installUtil is found or not. If not then give an appropriate message
# and exit.
if (Test-Path $installUtilDir)
{
    Write-Host "Installutil path could not be found."
    Write-Host ".NET Framework might be broken on your system."
    Write-Host "Please repair .NET Framework and try again."
    Exit
}

# Check if the Nutanix snapin is already added in this Powershell session.
# If not, then add the snapin.
$loaded = Get-PSSnapin -Name NutanixCmdletsPSSnapin `
    -ErrorAction SilentlyContinue | % {$_.Name}
if ($loaded -eq $null)
{
    Add-PSSnapin NutanixCmdletsPSSnapin
}

# Function to check if the type is enum and if the type is found to be enum,
# array of enum values is returned.
function getEnumValues($type)
{
    if ($type.IsEnum)
    {
        $values = [System.Enum]::GetValues($type)
    }

    return $values
}

$global:originalFunction = $function:TabExpansion

# This function is called by powershell by default whenever tab is pressed. Thus
# it is extended to support the tab expansion for enum values.
function global:TabExpansion
{
    # Tab expansion function in Powershell expects two parameters, line and
    # lastWord. The first parameter is the full line typed by the user and
    # second parameter is the last word/letter typed by user before pressing
    # tab. Thus if user types "Get-NTNXAlert -i" and presses tab, then first
    # parameter is the complete line : "Get-NTNXAlert -i" and the second
    # parameter is "i".
    param($line, $lastWord)

    $originalRes = & $global:originalFunction $line $lastWord

    # If the inbuilt tab expansion function returns some value then return
    # that value.
    if ($originalRes)
    {
        return $originalRes
    }

    # Tokenize the whole line entered by the user and get each token as type
    # "token" in powershell. This is needed to get complete line which was
    # entered by the user, tokenized in form of powershell tokens so that we can
    # check the type of the last token etc.
    $tokens = [System.Management.Automation.PSParser]::Tokenize( `
        $line, [ref] $null)

    if ($tokens)
    {
        $lastVal = $tokens[$tokens.count - 1]

        $startVal = ""

        # Check the type of the last token.
        switch($lastVal.Type)
        {
            # If the last token is CommandParameter type then just store it
            # directly.
            'CommandParameter'
            {
                $paramToken = $lastVal
            }

            # If the last token is CommandArgument, then the parameter name will
            # be the second last entry in the "tokens" array.
            'CommandArgument'
            {
                if($lastWord)
                {
                    $startVal = $lastWord

                    $prevToken = $tokens[$tokens.count - 2]
                    if ($prevToken.Type -eq 'CommandParameter')
                    {
                        $paramToken = $prevToken
                    }
                }
            }
        }

        # If user pressed tab after entering the parameter name then we need to
        # check if the parameter is of type enum or list of type enum. For doing
        # this we need to extract the cmdlet name from the list of tokens.
        if ($paramToken)
        {
            [int]$groupLevel = 0
            for($i = $tokens.Count-1; $i -ge 0; $i--)
            {
                $currentToken = $tokens[$i]
                if (($currentToken.Type -eq 'Command') -and `
                    ($groupLevel -eq 0) )
                {
                    $cmdletToken = $currentToken
                    break;
                }

                if ($currentToken.Type -eq 'GroupEnd')
                {
                   $groupLevel += 1
                }

                if ($currentToken.Type -eq 'GroupStart')
                {
                    $groupLevel -= 1
                }
            }

            if ($cmdletToken)
            {
                # Get the complete definition of the cmdlet for which user
                # pressed tab.
                $cmdlet = Get-Command $cmdletToken.Content
                $parameter = `
                    $cmdlet.Parameters[$paramToken.Content.Replace('-','')]

                $parameterType = $parameter.ParameterType

                # Get the vaues of the enum type if the parameter was of type
                # enum or list/array of type enum.
                if ($parameterType.IsEnum)
                {
                    $values = getEnumValues($parameterType)
                }
                elseif ($parameterType.IsArray)
                {
                    $elementType = $parameterType.GetElementType()
                    $values = getEnumValues($elementType)
                }
                elseif ($parameterType.Name.Contains("List"))
                {
                    $genericType = $parameterType.GetGenericArguments()[0]
                    $values = getEnumValues($genericType)
                }

                if($values)
                {
                    if ($startVal)
                    {
                        return ($values | where { $_ -like "${startVal}*" })
                    }
                    else
                    {
                        return $values
                    }
                }
            }
        }
    }
}




#endregion Loading cmdlets completed

#region Nutanix Connection 
## Steven Potrais - Connecting to the Nutanix node

$nxServerObj = Connect-NutanixCluster -Server $nxIP -UserName $nxUser -Password $nxPassword -AcceptInvalidSSLCerts
 
# Connect-NutanixCluster -Server 1.1.1.1 -UserName admin -Password admin -AcceptInvalidSSLCerts