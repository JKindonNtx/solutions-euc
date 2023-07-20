$EventLogs = wevtutil enum-logs
ForEach ($EventLog in $EventLogs) {
    wevtutil cl "$EventLog" 2> $null
}
wevtutil cl "System"