# 
# Create Delivery Group 'AHV - Windows - 10 - Delivery Group Name'
# 
# 4/5/2019 11:53 AM
# 
Get-LogSite  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ********

Start-LogHighLevelOperation  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -Source "Studio" -StartTime "4/5/2019 9:53:18 AM" -Text "Create Delivery Group `'AHV - Windows - 10 - Delivery Group Name`'"

Get-BrokerMachine  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -Filter {(Uid -eq 1211)} -MaxRecordCount 1

New-BrokerDesktopGroup  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -ColorDepth "TwentyFourBit" -DeliveryType "DesktopsOnly" -DesktopKind "Private" -InMaintenanceMode $False -IsRemotePC $False -LoggingId "358f2c77-d5f7-4d10-9b6b-1f245d97239c" -MinimumFunctionalLevel "L7_9" -Name "AHV - Windows - 10 - Delivery Group Name" -OffPeakBufferSizePercent 10 -OffPeakDisconnectAction "Nothing" -OffPeakDisconnectTimeout 0 -OffPeakExtendedDisconnectAction "Nothing" -OffPeakExtendedDisconnectTimeout 0 -OffPeakLogOffAction "Nothing" -OffPeakLogOffTimeout 0 -PeakBufferSizePercent 10 -PeakDisconnectAction "Nothing" -PeakDisconnectTimeout 0 -PeakExtendedDisconnectAction "Nothing" -PeakExtendedDisconnectTimeout 0 -PeakLogOffAction "Nothing" -PeakLogOffTimeout 0 -PublishedName "AHV - Windows - 10 - Delivery Group Name" -Scope @() -SecureIcaRequired $False -SessionSupport "SingleSession" -ShutdownDesktopsAfterUse $True -TimeZone "W. Europe Standard Time"

Add-BrokerMachine  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -DesktopGroup "AHV - Windows - 10 - Delivery Group Name" -InputObject @(1211,1210,1213,1212,1214,1208,1206,1207,1224,1209,1217,1216,1215,1222,1218,1225,1221,1219,1220,1223,1226,1227,1230,1235,1236,1238,1228,1237,1229,1231,1234,1233,1232,1240,1239,1247,1241,1245,1242,1243,1248,1251,1249,1246,1250,1244,1252,1253,1254,1255) -LoggingId "358f2c77-d5f7-4d10-9b6b-1f245d97239c"

Test-BrokerAccessPolicyRuleNameAvailable  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -Name @("AHV - Windows - 10 - Delivery Group Name_Direct")

New-BrokerAccessPolicyRule  -AdminAddress "contmxd002.contoso.local:80" -AllowedConnections "NotViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -BearerToken ******** -DesktopGroupUid 1 -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedUserFilterEnabled $True -IncludedUsers @() -LoggingId "358f2c77-d5f7-4d10-9b6b-1f245d97239c" -Name "AHV - Windows - 10 - Delivery Group Name_Direct"

Test-BrokerAccessPolicyRuleNameAvailable  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -Name @("AHV - Windows - 10 - Delivery Group Name_AG")

New-BrokerAccessPolicyRule  -AdminAddress "contmxd002.contoso.local:80" -AllowedConnections "ViaAG" -AllowedProtocols @("HDX","RDP") -AllowedUsers "AnyAuthenticated" -AllowRestart $True -BearerToken ******** -DesktopGroupUid 1 -Enabled $True -IncludedSmartAccessFilterEnabled $True -IncludedSmartAccessTags @() -IncludedUserFilterEnabled $True -IncludedUsers @() -LoggingId "358f2c77-d5f7-4d10-9b6b-1f245d97239c" -Name "AHV - Windows - 10 - Delivery Group Name_AG"

Test-BrokerPowerTimeSchemeNameAvailable  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -Name @("AHV - Windows - 10 - Delivery Group Name_Weekdays")

New-BrokerPowerTimeScheme  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -DaysOfWeek "Weekdays" -DesktopGroupUid 1 -DisplayName "Weekdays" -LoggingId "358f2c77-d5f7-4d10-9b6b-1f245d97239c" -Name "AHV - Windows - 10 - Delivery Group Name_Weekdays" -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

Test-BrokerPowerTimeSchemeNameAvailable  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -Name @("AHV - Windows - 10 - Delivery Group Name_Weekend")

New-BrokerPowerTimeScheme  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -DaysOfWeek "Weekend" -DesktopGroupUid 1 -DisplayName "Weekend" -LoggingId "358f2c77-d5f7-4d10-9b6b-1f245d97239c" -Name "AHV - Windows - 10 - Delivery Group Name_Weekend" -PeakHours @($False,$False,$False,$False,$False,$False,$False,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False,$False,$False) -PoolSize @(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

Stop-LogHighLevelOperation  -AdminAddress "contmxd002.contoso.local:80" -BearerToken ******** -EndTime "4/5/2019 9:53:21 AM" -HighLevelOperationId "358f2c77-d5f7-4d10-9b6b-1f245d97239c" -IsSuccessful $True
# Script completed successfully