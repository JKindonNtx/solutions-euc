$Fileshare = "\\ws-files.wsperf.nutanix.com\backup"
$currentdate = get-date -Format yyyyMMdd
if (-not (Test-Path "$Fileshare\Grafana\$($currentdate)")) { New-Item -ItemType Directory -Path "$Fileshare\Grafana\$($currentdate)" | Out-Null }
if (-not (Test-Path "$Fileshare\InfluxDB\$($currentdate)")) { New-Item -ItemType Directory -Path "$Fileshare\InfluxDB\$($currentdate)" | Out-Null }
Stop-Service -Name "Grafana"
Compress-Archive -Path "C:\Program Files\GrafanaLabs\grafana\bin" -DestinationPath "$Fileshare\Grafana\$($currentdate)\BackupGrafana.zip"
Start-Service -Name "Grafana"
C:\Tools\influxdb2-client-2.7.3\influx.exe backup $Fileshare\InfluxDB\$currentdate
Get-ChildItem -Path "$Fileshare" -Directory -recurse| where {$_.LastWriteTime -le $(get-date).Adddays(-10)} | Remove-Item -recurse -force