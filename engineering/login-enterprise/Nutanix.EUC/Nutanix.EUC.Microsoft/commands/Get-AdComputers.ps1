function Get-AdComputers(){

    param(
        [string] $filter,
        [string] $UserName,
        [string] $Password,
        [string] $BaseDN,
        [string] $LDAPServer
    )

    try {
        $SearchFilter = "$($filter)*"

        $ldapSearchResults = ldapsearch -LLL -D "$($UserName)" -w "$($Password)" -p 389 -h $($LDAPServer) -b "$($BaseDN)" -s sub -x "(&(objectclass=computer)(name=$($Filter)*))" name | grep name:
        $AdComputers = @()
        foreach ($Server in $ldapSearchResults){
            $trimmedServer = $Server.Replace("name: ", "")
            $AdComputers += $trimmedServer
        }
    } catch {

        Write-Log -Message $_ -Level Error
        Break
    }

    return $AdComputers
}