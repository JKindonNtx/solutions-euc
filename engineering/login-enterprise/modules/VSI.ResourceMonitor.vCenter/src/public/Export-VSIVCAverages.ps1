function Export-VSIVCAverages {
    param(
        $Folder,
        $FilePrefix
    )
    $VMRawPath = "$($Folder)\VM Raw.csv"
    $HostRawPath = "$($Folder)\Host Raw.csv"
    if (Test-Path $VMRawPath) {
        $VMRaw = Import-Csv -Path $VMRawPath
    }
    if (Test-Path $HostRawPath) {
        $HostRaw = Import-Csv -Path $HostRawPath
    }
    if ($null -ne $VMRaw) {
        # Calculate averages
        # VM Averages
        $Groups = $VMRaw | Group-Object -Property Minute
        $VMAverages = @()
        foreach ($Group in $Groups) {
            $VMAverage = New-Object psobject
            $VMAverage | Add-Member -MemberType NoteProperty -Name "Minute" -Value $Group.Name
            $props = $group.group[0].psobject.properties | Where-Object { $_.name -ne "Name" -and $_.name -ne "Minute" -and $_.name -ne "Host" } | Select-Object -expand name
            foreach ($prop in $props) {
                $VMAverage | Add-Member -MemberType NoteProperty -Name $prop -Value ($group.Group | Measure-Object -Property $prop -Average | Select-Object -ExpandProperty Average)
            }
            $VMAverages += $VMAverage
        }
        $VMAverages | Export-Csv -Path "$($Folder)\VM Averages.csv"
    }
    if ($null -ne $HostRaw) {
        # Host averages
        $Groups = $HostRaw | Group-Object -Property Minute
        $HostAverages = @()
        foreach ($Group in $Groups) {
            $HostAverage = New-Object psobject
            $HostAverage | Add-Member -MemberType NoteProperty -Name "Minute" -Value $Group.Name
            $props = $group.group[0].psobject.properties | Where-Object { $_.name -ne "Name" -and $_.name -ne "Minute" -and $_.name -ne "Host" } | Select-Object -expand name
            foreach ($prop in $props) {
                $HostAverage | Add-Member -MemberType NoteProperty -Name $prop -Value ($group.Group | Measure-Object -Property $prop -Average | Select-Object -ExpandProperty Average)
            }
            $HostAverages += $HostAverage

        }
        $HostAverages | Export-Csv -Path "$($Folder)\Host Averages.csv"
    }
    if (($null -ne $HostRaw) -and ($null -ne $VMRaw)) {
        # VM per Host averages
        $Groups = $VMRaw | Group-Object -Property Minute, Host
        $VMHostAverages = @()
        foreach ($Group in $Groups) {
            $VMHostAverage = New-Object psobject
            $VMHostAverage | Add-Member -MemberType NoteProperty -Name "Minute" -Value $Group.Name.Split(",")[0]
            $VMHostAverage | Add-Member -MemberType NoteProperty -Name "Host" -Value $Group.Name.Split(",")[1].Trim()
            $props = $group.group[0].psobject.properties | Where-Object { $_.name -ne "Name" -and $_.name -ne "Minute" -and $_.name -ne "Host" } | Select-Object -expand name
            foreach ($prop in $props) {
                $VMHostAverage | Add-Member -MemberType NoteProperty -Name $prop -Value ($group.Group | Measure-Object -Property $prop -Average | Select-Object -ExpandProperty Average)
            }
            $VMHostAverages += $VMHostAverage
        }
        $HostAverages | Export-Csv -Path "$($Folder)\VM Averages per host.csv"
    }
}