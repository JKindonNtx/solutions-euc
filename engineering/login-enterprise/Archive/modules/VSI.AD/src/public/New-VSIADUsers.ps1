function New-VSIADUsers {
    param(
        $BaseName,
        $Amount,
        $Password,
        $NumberOfDigits,
        $DomainLDAPPath,
        $OU,
        $LDAPUsername,
        $LDAPPassword,
        $ApplianceURL,
        $LogonApp
    )

    Write-Log "Creating OUs, users and groups in AD if required"
    if ($null -eq $LogonApp) {
        $LogonScript = "LoginPI.Logon.exe $ApplianceURL"
    }
    else {
        $LogonScript = "$LogonApp $ApplianceURL"
    }

    #$DomainLDAPPath = "LDAP://10.50.1.10/DC=lab,DC=loginvsi,DC=com"
    If ([string]::IsNullOrEmpty($LDAPUsername)) {
        $DE = New-Object System.DirectoryServices.DirectoryEntry($DomainLDAPPath)
    }
    else {
        $DE = New-Object System.DirectoryServices.DirectoryEntry($DomainLDAPPath, $LDAPUsername, $LDAPPassword)
    }
    $OUList = New-Object System.Collections.ArrayList
    #$OU = "OU=TestUsers,OU=TestHenk"

    $OU.Split(",") | ForEach-Object { $OUList.Add($_) | Out-Null }
    $OUList.Reverse()
    $newOU = $DE
    Foreach ($aOU in $OUList) {
        #Write-Host "Attemting to create $aOU in $($newOU.Path)"
        if ($null -ne ($newOU.Children | Where-Object { $_.distinguishedName -like "$($aOU)*" })) {
            #Write-Host "$OU already exists"
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
        If ([string]::IsNullOrEmpty($LDAPUsername)) {
            $Parent = New-Object System.DirectoryServices.DirectoryEntry($User.Parent)
        }
        else {
            $Parent = New-Object System.DirectoryServices.DirectoryEntry($User.Parent, $LDAPUsername, $LDAPPassword)
        }
        $Parent.Children.Remove($User)
        $Parent.CommitChanges()
    }
    $DS = New-Object System.DirectoryServices.DirectorySearcher($newOU, "(&(objectClass=group)(cn=$($BaseName)))")
    $DS.PageSize = 1000
    Foreach ($Result in $DS.FindAll()) {
        $Group = $Result.GetDirectoryEntry()
        If ([string]::IsNullOrEmpty($LDAPUsername)) {
            $Parent = New-Object System.DirectoryServices.DirectoryEntry($Group.Parent)
        }
        else {
            $Parent = New-Object System.DirectoryServices.DirectoryEntry($Group.Parent, $LDAPUsername, $LDAPPassword)
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
        Write-Verbose "Creating $Name in $($newOU.Path)"
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


    Write-Log "Created $Amount users with BaseName $BaseName in $OU"
    Write-Log "Created Group $BaseName in $OU"
    if ($null -eq $LogonApp) {
        Write-Log "IMPORTANT: DO NOT FORGET TO COPY THE LOGIN ENTERPRISE LOGONAPP TO THE NETLOGON SHARE!!!"
        Write-Log "Download it from $ApplianceURL/contentDelivery/content/zip/logon.zip"
    }
    else {
        Write-Log "IMPORTANT: Make sure the logonApp is located at $LogonApp"
        Write-Log "Download it from $ApplianceURL/contentDelivery/content/zip/logon.zip"
    }

}