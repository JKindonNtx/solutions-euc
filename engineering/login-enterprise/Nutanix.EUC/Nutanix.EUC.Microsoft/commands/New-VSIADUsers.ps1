function New-VSIADUsers {
    <#
    .SYNOPSIS
    Quick Description of the function.

    .DESCRIPTION
    Detailed description of the function.

    .PARAMETER ParameterName
    Description of each parameter being passed into the function.

    .INPUTS
    This function will take inputs via pipeline.

    .OUTPUTS
    What the function returns.

    .EXAMPLE
    PS> function-template -parameter "parameter detail"
    Description of the example.

    .LINK
    Markdown Help: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Help/function-template.md

    .LINK
    Project Site: https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/login-enterprise/Nutanix.EUC

#>
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory = $false)]$BaseName,
        [Parameter(Mandatory = $false)]$Amount,
        [Parameter(Mandatory = $false)]$Password,
        [Parameter(Mandatory = $false)]$NumberOfDigits,
        [Parameter(Mandatory = $false)]$DomainLDAPPath,
        [Parameter(Mandatory = $false)]$OU,
        [Parameter(Mandatory = $false)]$LDAPUsername,
        [Parameter(Mandatory = $false)]$LDAPPassword,
        [Parameter(Mandatory = $false)]$ApplianceURL,
        [Parameter(Mandatory = $false)]$LogonApp
    )


        Write-Log -Message "Creating OUs, users and groups in AD if required" -Level Info

        if ($null -eq $LogonApp) {
            $LogonScript = "LoginPI.Logon.exe $ApplianceURL"
        }
        else {
            $LogonScript = "$LogonApp $ApplianceURL"
        }

        try {
            If ([string]::IsNullOrEmpty($LDAPUsername)) {
                $DE = New-Object System.DirectoryServices.DirectoryEntry($DomainLDAPPath) -ErrorAction Stop
            }
            else {
                $DE = New-Object System.DirectoryServices.DirectoryEntry($DomainLDAPPath, $LDAPUsername, $LDAPPassword) -ErrorAction Stop
            }
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        

        $OUList = New-Object System.Collections.ArrayList

        $OU.Split(",") | ForEach-Object { $OUList.Add($_) | Out-Null }
        $OUList.Reverse()
        $newOU = $DE

        Foreach ($aOU in $OUList) {
            if ($null -ne ($newOU.Children | Where-Object { $_.distinguishedName -like "$($aOU)*" })) {
                $newOU = $newOU.Children | Where-Object { $_.distinguishedName -like "$($aOU)*" }
            }
            else {
                $newOU = $newOU.Children.Add($aOU, "organizationalUnit")
                $newOU.CommitChanges()
            }
        }

        $DS = New-Object System.DirectoryServices.DirectorySearcher($newOU, "(&(objectClass=user)(cn=$($BaseName)*))")
        $DS.PageSize = 1000

        Foreach ($Result in $DS.FindAll()) {
            $User = $Result.GetDirectoryEntry()
            try {
                If ([string]::IsNullOrEmpty($LDAPUsername)) {
                    $Parent = New-Object System.DirectoryServices.DirectoryEntry($User.Parent) -ErrorAction Stop
                }
                else {
                    $Parent = New-Object System.DirectoryServices.DirectoryEntry($User.Parent, $LDAPUsername, $LDAPPassword) -ErrorAction Stop
                }
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
            
            $Parent.Children.Remove($User)
            $Parent.CommitChanges()
        }

        try {
            $DS = New-Object System.DirectoryServices.DirectorySearcher($newOU, "(&(objectClass=group)(cn=$($BaseName)))") -ErrorAction Stop
            $DS.PageSize = 1000
        }
        catch {
            Write-Log -Message $_ -Level Error
            Break
        }
        

        Foreach ($Result in $DS.FindAll()) {
            $Group = $Result.GetDirectoryEntry()
            try {
                If ([string]::IsNullOrEmpty($LDAPUsername)) {
                    $Parent = New-Object System.DirectoryServices.DirectoryEntry($Group.Parent) -ErrorAction Stop
                }
                else {
                    $Parent = New-Object System.DirectoryServices.DirectoryEntry($Group.Parent, $LDAPUsername, $LDAPPassword) -ErrorAction Stop
                }
            }
            catch {
                Write-Log -Message $_ -Level Error
                Break
            }
            
            $Parent.Children.Remove($Group)
            $Parent.CommitChanges()
        }

        <#
        GLOBAL       | SECURITY = 0x80000002 = -2147483646
        DOMAIN_LOCAL | SECURITY = 0x80000004 = -2147483644
        UNIVERSAL    | SECURITY = 0x80000008 = -2147483640
        #>

        $group = $newOU.Children.Add("CN=$BaseName", "group")
        $group.Properties["displayName"].Value = $BaseName
        $group.Properties["samAccountName"].Value = $BaseName
        $group.Properties["groupType"].Value = -2147483646
        $group.CommitChanges()

        $group = $newOU.Children | Where-Object { $_.distinguishedName -like "CN=$($basename),$($newOU.distinguishedName)" -and $_.SchemaClassName -eq "group" }

        For ($i = 1; $i -le $amount; $i++) {
            $user = $Null
            $Name = "$($BaseName){0:D$NumberOfDigits}" -f $i
            $user = $newOU.Create("user", "cn=$Name")
            $user.Put("samAccountName", $Name) | Out-Null
            $user.Put("mail", "$Name@wsperf.nutanix.com") | Out-Null
            $user.Put("displayName", $Name) | Out-Null
            $user.Put("givenName", $Name) | Out-Null
            $user.Put("name", $Name) | Out-Null
            $user.Put("scriptPath", $LogonScript) | Out-Null
            $user.Put("userPrincipalName", "$($Name)@wsperf.nutanix.com") | Out-Null
            $user.Put("userAccountControl", 66080) | Out-Null
            $user.SetInfo() | Out-Null
            $user.SetPassword($Password) | Out-Null
            $group.Properties["member"].Add($user.Properties["distinguishedName"].Trim()) | Out-Null
            $group.CommitChanges()
        }

        Write-Log -Message "Created $Amount users with BaseName $BaseName in $OU" -Level Info
        Write-Log -Message "Created Group $BaseName in $OU" -Level Info

        if ($null -eq $LogonApp) {
            Write-Log -Message "IMPORTANT: DO NOT FORGET TO COPY THE LOGIN ENTERPRISE LOGONAPP TO THE NETLOGON SHARE!!!" -Level Info
            Write-Log -Message "Download it from $ApplianceURL/contentDelivery/content/zip/logon.zip" -Level Info
        }
        else {
            Write-Log -Message "IMPORTANT: Make sure the logonApp is located at $LogonApp" -Level Info
            Write-Log -Message "Download it from $ApplianceURL/contentDelivery/content/zip/logon.zip" -Level Info
        }


}
