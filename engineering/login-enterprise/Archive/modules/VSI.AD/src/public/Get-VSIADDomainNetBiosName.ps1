function Get-VSIADDomainNetbiosName {
    param(
        $domainName
    )
    $RootDSE = [ADSI]"LDAP://RootDSE"
    $ConfigurationDE = New-object System.DirectoryServices.DirectoryEntry("LDAP://CN=Partitions," + $RootDSE.configurationNamingContext)
    # Search for Netbiosname of the specified domain
    $sSearchString = "(&(objectclass=Crossref)(dnsRoot=" + $sDomainName + ")(netBIOSName=*))"
    $oSearch = New-Object directoryservices.DirectorySearcher($oADSearchRoot, $sSearchString)
    $sNetBIOSName = ($oSearch.FindOne()).Properties["netbiosname"]
    # Print out
    Write-Host "Domain NetBIOS Name:" $sNetBIOSName
}