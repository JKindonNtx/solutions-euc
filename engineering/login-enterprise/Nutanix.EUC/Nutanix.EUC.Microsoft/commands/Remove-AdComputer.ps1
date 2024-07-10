function Remove-AdComputer(){

    param(
        [string] $UserName,
        [string] $Password,
        [string] $BaseDN,
        [string] $LDAPServer
    )

    try {
        $ldapDelete = ldapdelete -D "$($UserName)" -w "$($Password)" -p 389 -h $($LDAPServer) "$($BaseDN)"
    } catch {
        
        Break
    }

    return $ldapDelete
}