Import-Module PScribo -Force;

Connect-NTNXCluster -AcceptInvalidSSLCerts 10.68.68.30 -Username Admin


<# The document name is used in the file output #>
$document = Document 'Nutanix Documentation' -Verbose {
    TOC -Name 'Table of Contents';
    PageBreak;
    
    <# WARNING:
        Microsoft Word will include paragraphs styled with 'Heading*' style names to the TOC.
        To avoid this, define an identical style with a name not beginning with 'Heading'!
    #>
#    Paragraph -Style Heading1 'This is Heading 1'
#    Paragraph -Style Heading2 'This is Heading 2'
#    Paragraph -Style Heading3 'This is Heading 3'
#    Paragraph 'This is a regular line of text indented 0 tab stops'
#    Paragraph -Tabs 1 'This is a regular line of text indented 1 tab stops. This text should not be displayed as a hanging indent, e.g. not just the first line of the paragraph indented.'
#    Paragraph -Tabs 2 'This is a regular line of text indented 2 tab stops'
#    Paragraph -Tabs 3 'This is a regular line of text indented 3 tab stops'
#    Paragraph 'This is a regular line of text in the default font in italics' -Italic
#    Paragraph 'This is a regular line of text in the default font in bold' -Bold
#    Paragraph 'This is a regular line of text in the default font in bold italics' -Bold -Italic
#    Paragraph 'This is a regular line of text in the default font in 14 point' -Size 14
#    Paragraph 'This is a regular line of text in Courier New font' -Font 'Courier New'
#    Paragraph "This is a regular line of text indented 0 tab stops with the computer name as data: $env:COMPUTERNAME"
#    Paragraph "This is a regular line of text indented 0 tab stops with the computer name as data in bold: $env:COMPUTERNAME" -Bold
#    Paragraph "This is a regular line of text indented 0 tab stops with the computer name as data in bold italics: $env:COMPUTERNAME" -Bold -Italic
#    Paragraph "This is a regular line of text indented 0 tab stops with the computer name as data in 14 point bold italics: $env:COMPUTERNAME" -Bold -Italic -Size 14
#    Paragraph "This is a regular line of text indented 0 tab stops with the computer name as data in 8 point Courier New bold italics: $env:COMPUTERNAME" -Bold -Italic -Size 8 -Font 'Courier New'
   
    $cluster = Get-NTNXCluster
    $HAInfo = Get-NTNXHA
    <# Add a custom style for highlighting table cells/rows #>
    # Style -Name 'Stopped Service' -Color White -BackgroundColor Firebrick -Bold
    
    <#  Sections provide an easy way of creating a document structure and can support automatic
        section numbering (if enabled with the GlobalOption -EnableSectionNumbering parameter. You
        don't need to worry about the numbers - PScribo will automatically figure this out. #>
    Section -Style Heading1 'Nutanix Cluster Information' {
        Section -Style Heading2 'Nutanix Cluster Configuration' {
            Paragraph -Style Heading3 'Nutanix general block info'
            Paragraph "Cluster ($($cluster.Count) Cluster(s) found):"
            $cluster | Table -Columns Name,clusterExternalIPAddress,Version,timezone,blockSerials -Headers 'Cluster Name','External IP','Acropolis Version','Time Zone','Serials' -Width 0
        
            Paragraph -Style Heading3 'Nutanix IP block info'
            $cluster | Table -Columns Name,externalSubnet,internalSubnet,enableLockDown,enablePasswordRemoteLoginToCluster -Headers 'Cluster Name','External Subnet','Internal Subnet','Lockdown','Remote Login Enabled' -Width 0
        
            Paragraph -Style Heading3 'Nutanix block configuration info'
            $cluster | Table -Columns Name,enableShadowClones,nameServers,ntpServers,hypervisorTypes,numNodes -ColumnWidths 10,10,20,20,20,20 -Headers 'Cluster Name','Shadow Clones','DNS','NTP','Hypervisors','Number of nodes' -Width 0
        
            Paragraph -Style Heading3 'Nutanix HA info'
            $HAInfo | Table -Columns failoverEnabled,numHostFailuresToTolerate,reservationType,haState -Headers 'Failover Enabled','Allowed host failures','Reservation Type','HA State' -Width 0
        
        }
      }

    PageBreak
    $clusterlicenseinfo = Get-NTNXClusterLicenseInfo
    $clusterlicense = Get-NTNXLicense
    $clusterlicenseallowance = Get-NTNXLicenseAllowance

     Section -Style Heading1 'Nutanix Licensing Information' {
        Section -Style Heading2 'Nutanix Cluster Licensing' {
            $clusterlicenseinfo | Table -Columns cluster_uuid,standby_mode,signature,block_serial_list -Headers 'Uuid','Standby','Signature','Serials' -Width 0
        }

         Section -Style Heading2 'Nutanix Licensing' {
            $clusterlicense | Table -Columns category,clusterExpiryUsecs,standbyMode -Headers 'Category','Expiry','Signature','Standby Mode' -Width 0
        }
         Section -Style Heading2 'Nutanix Licensed features' {
            $clusterlicenseallowance | Table -Columns key,value -Headers 'Function','Enabled' -Width 0
        }
      }
  PageBreak
    $RackableUnit = Get-NTNXRackableUnit
    $RemoteSupport = Get-NTNXRemoteSupportSetting
    $SMTPConfig = Get-NTNXSmtpServer
    $NTNXHost = Get-NTNXHost


     Section -Style Heading1 'Nutanix System Information' {
        Section -Style Heading2 'Nutanix System Information' {
            $RackableUnit | Table -Columns id,model,location,serial,positions -Headers 'id','Model','Location','Serial','Positions' -Width 0
        }

         Section -Style Heading2 'Remote Support Settings' {
            $RemoteSupport | Table -Columns enable,tunneldetails -Headers 'Remote Support','Details' -Width 0
        }
         Section -Style Heading2 'SMTP Settings' {
            $SMTPConfig | Table -Columns address,port,username,password,secureMode,fromEmailAddress -Headers 'SMTP Server','Port','Username','Password','Secure Mode', 'Email Address' -Width 0
        }
         Section -Style Heading2 'IP configuration' {
            $NTNXHost | Table -Columns name,blockModel,hypervisorFullName,serviceVMExternalIP,hypervisorAddress,ipmiAddress,State -Headers 'Name','Model','Hypervisor','CVM','Hypervisor IP','IPMI Address','State' -Width 0
        }
         Section -Style Heading2 'Serial Configuration' {
            $NTNXHost | Table -Columns name,serial,blockSerial,state -Headers 'Name','Node Serial','Block Serial' -Width 0
        }
         Section -Style Heading2 'CPU configuration' {
            $NTNXHost | Table -Columns name,cpuModel,numCpuSockets,numCpuCores -Headers 'Name','CPU Model','Number of Sockets','Number of Cores' -Width 0
        }
         Section -Style Heading2 'Memory Configuration' {
            $NTNXHost | Table -Columns Name,memoryCapacityInBytes -Headers 'Name','Memory in Bytes' -Width 0
        }
      }
  PageBreak
    $AuthDir = Get-NTNXAuthConfigDirectory
     Section -Style Heading1 'Nutanix Authentication' {
        Section -Style Heading2 'Nutanix Authentication Configuration' {
            $AuthDir | Table -Columns name,directoryType,connectionType,directoryURL,domain -Headers 'Name','Directory Type','Connection','URL','Domain' -Width 0
      }
    }
  PageBreak
    $CmdLetsInfo = Get-NutanixCmdletsInfo
     Section -Style Heading1 'Nutanix General Information' {
        Section -Style Heading2 'Nutanix CMDlets Info' {
            $CmdLetsInfo | Table -Columns version,BuildVersion,RestAPIVersion -Width 0
      }
    }
  PageBreak
    $StoragePool = Get-NTNXStoragePool
    $Container = Get-NTNXContainer
    $datastore = Get-NTNXNfsDatastore
     Section -Style Heading1 'Nutanix Storage Pool Information' {
        Section -Style Heading2 'Nutanix Storage Pool' {
            $StoragePool | Table -Columns name,capacity,reservedCapacity,ilmDownMigratePctThreshold -Headers 'Name','Capacity','Reserved Capacity','ILM Treshold' -Width 0
      }
         Section -Style Heading2 'Nutanix Containers' {
            $Container | Table -Columns Name,markedForRemoval,maxCapacity,totalExplicitReservedCapacity,totalImplicitReservedCapacity -Headers 'Name','Marked for removal','Max Capacity','Explisit Reserved','Implicit Reservered' -Width 0
      }
         Section -Style Heading2 'Nutanix Container Settings' {
            $Container | Table -Columns Name,replicationFactor,oplogReplicationFactor,erasureCode,fingerPrintOnWrite,onDiskDedup,compressionEnabled,compressionDelayInSecs -Headers 'Name','RF','RF OpLog','EC-X','Fingerprint on Write','OnDisk Dedup','Compression Enabled','Compression Delay' -Width 0
      }
        Section -Style Heading2 'Nutanix NFS Datastore Information' {
            $datastore | Table -Columns containerName,hostid,hostIpAddress,capacity,freeSpace -Headers 'Name','Host ID','Host IP','Capacity','Free Capacity' -Width 0
      }
    }
  PageBreak
    $Diskconfig = Get-NTNXDisk
     Section -Style Heading1 'Nutanix Disk Information' {
        Section -Style Heading2 'Nutanix Disk Configuration' {
            $Diskconfig | Table -Columns id,mountPath,diskSize,cvmIpAddress,storageTierName,location,diskStatus,online -Headers 'ID','Mount Path','Disk Size','CVM IP','Tier','Location','Status','Online' -Width 0
      }
  PageBreak
    $vDiskconfig = Get-NTNXVDisk
     Section -Style Heading1 'Nutanix vDisk Information' {
        Section -Style Heading2 'Nutanix vDisks' {
            $vDiskconfig | Table -Columns nfsFileName,containerName,storagePoolName,nfsFile,snapshot,maxCapacityBytes,onDiskDedup,erasureCode -Headers 'NFS FileName','Container Name','Storage Pool','NFS File','Snapshot','Disk Size','Dedup','EC-X' -Width 0
      }
 PageBreak
    $NTNXPD = Get-NTNXProtectionDomain
    $NTNXPDCG = Get-NTNXProtectionDomainConsistencyGroup
    $NTNXSNAP = Get-NTNXProtectionDomainSnapshot
    $NTNXUPVM = Get-NTNXUnprotectedVm
     Section -Style Heading1 'Nutanix Protection Domains' {
        Section -Style Heading2 'Nutanix Protection Domains' {
            $NTNXPD | Table -Columns name,active,pendingReplicationCount,ongoingReplicationCount,totalUserWrittenBytes,syncReplications -Headers 'Name','Active','Pending Replication','Current Replication','Written Bytes','Sync Replications' -Width 0
        }
        Section -Style Heading2 'Nutanix Protection Domain Consistency Group' {
            $NTNXPDCG | Table -Columns protectionDomainName,consistencyGroupName,withinSnapshot,appConsistentSnapshots,vmCount -Headers 'Name','Group Name','Snapshots','App Consistent Snapshot','VMs' -Width 0
        }
        Section -Style Heading2 'Nutanix Protection Domain Snapshots' {
            $NTNXSNAP | Table -Columns protectionDomainName,snapshotID,consistencyGroups,SizeInBytes -Headers 'Name','Snapshot ID','Host IP','Consistency Group','Size' -Width 0
        }
        Section -Style Heading2 'Nutanix Protection Domain Unprotected VMs' {
            $NTNXUPVM | Table -Columns vmName,guestOperatingSystem,hostName -Headers 'Name','OS','Hypervisor Host' -Width 0
      }
  PageBreak
    $NTNXALLVMs = Get-NTNXVM
     Section -Style Heading1 'Nutanix All VMs' {
        Section -Style Heading2 'Nutanix All VMs' {
            $NTNXALLVMs | Table -Columns vmName,powerState,guestOperatingSystem,memoryCapacityInBytes,numVCpus,numNetworkAdapters,diskCapacityInBytes -Headers 'Name','Power','OS','Memory','vCPU','NICs','Disk Size' -Width 0
        }
       }
      }
     }
    }
   }
<#  Generate 'PScribo Demo 1.html' files. Other supported formats include 'Word', 'HTML', 'Text' and 'Xml' #>
$document | Export-Document -Path ~\Desktop -Format Html -Verbose;

# SIG # Begin signature block
# MIIXtwYJKoZIhvcNAQcCoIIXqDCCF6QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4ib3VZRxF+hgA2VeIKMCaUyu
# aTqgghLqMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUZMIIEAaADAgECAhADViTO4HBjoJNSwH9//cwJMA0GCSqGSIb3DQEBCwUAMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0EwHhcNMTUwNTE5MDAwMDAwWhcNMTcwODIzMTIwMDAw
# WjBgMQswCQYDVQQGEwJHQjEPMA0GA1UEBxMGT3hmb3JkMR8wHQYDVQQKExZWaXJ0
# dWFsIEVuZ2luZSBMaW1pdGVkMR8wHQYDVQQDExZWaXJ0dWFsIEVuZ2luZSBMaW1p
# dGVkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqLQmabdimcQtYPTQ
# 9RSjv3ThEmFTRJt/MzseYYtZpBTcR6BnSfj8RfkC4aGZvspFgH0cGP/SNJh1w67b
# iX9oT5NFL9sUJHUsVdyPBA1LhpWcF09PP28mGGKO3oQHI4hTLD8etiIlF9qFantd
# 1Pmo0jdqT4uErSmx0m4kYGUUTa5ZPAK0UZSuAiNX6iNIL+rj/BPbI3nuPJzzx438
# oHYkZGRtsx11+pLA6hIKyUzRuIDoI7JQ0nZ0MkCziVyc6xGfS54JVLaVCEteTKPz
# Gc4yyvCqp6Tfe9gs8UuxJiEMdH5fvllTU4aoXbm+W8tonkE7i/19rv8S1A2VPiVV
# xNLbpwIDAQABo4IBuzCCAbcwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt9mV1
# DlgwHQYDVR0OBBYEFP2RNOWYipdNCSRVb5jIcyRp9tUDMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOgMYYv
# aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmww
# QgYDVR0gBDswOTA3BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzCBhAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUFBzAB
# hhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6Ly9j
# YWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNIQTJBc3N1cmVkSURDb2RlU2ln
# bmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQCclXHR
# DhDyJr81eiD0x+AL04ryDwdKT+PooKYgOxc7EhRn59ogxNO7jApQPSVo0I11Zfm6
# zQ6K6RPWhxDenflf2vMx7a0tIZlpHhq2F8praAMykK7THA9F3AUxIb/lWHGZCock
# yD/GQvJek3LSC5NjkwQbnubWYF/XZTDzX/mJGU2DcG1OGameffR1V3xODHcUE/K3
# PWy1bzixwbQCQA96GKNCWow4/mEW31cupHHSo+XVxmjTAoC93yllE9f4Kdv6F29H
# bRk0Go8Yn8WjWeLE/htxW/8ruIj0KnWkG+YwmZD+nTegYU6RvAV9HbJJYUEIfhVy
# 3DeK5OlY9ima2sdtMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkq
# hkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBB
# c3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAw
# WjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3Vy
# ZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6
# kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQj
# ZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5w
# MWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp
# 6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH
# 5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgw
# BgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYI
# KwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5j
# b20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdp
# Q2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6
# Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmww
# OqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUH
# AgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYD
# VR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuC
# MS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2
# qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4Q
# pO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEp
# KBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/Dm
# ZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9
# CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHv
# MYIENzCCBDMCAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNl
# cnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQQIQA1YkzuBwY6CTUsB/
# f/3MCTAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkq
# hkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGC
# NwIBFTAjBgkqhkiG9w0BCQQxFgQUcMs4EykGGRwX+6diI5vx7WldROcwDQYJKoZI
# hvcNAQEBBQAEggEAMiskf3LeLMepLneys7hm8C2zVfjCLV/C1nB5Xs2JSbbrgTJu
# NAvDvFEntx/OwKvOtCdcnvAM4kO2w/vakpAYu0gCLA/4YfuDMJTKW4Evg3zTJ6of
# okIvFZrjdx3na004/em1Sa5J5GK3ulFQrMjWa0BOjreP3u/v3YXrU1rH3buz7dMZ
# x/AIhMitwNamZ6RRFUejJpBOZEUrqJIRH/UtdN/F7csAzsTt8hLjKN+yPzMpST4X
# 0/IVzKA7GLZDzqGPPHlgIeewPVAyXHJjQGGMlnfSNz1D6olTHMgi/EkUzKht7Foc
# NxERb+Xww7Bj6eRbs1rS8T0K7KdTCLbFEWp4CaGCAgswggIHBgkqhkiG9w0BCQYx
# ggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBD
# b3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2
# aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAYBgkq
# hkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xNTA3MDcxMDAw
# NTFaMCMGCSqGSIb3DQEJBDEWBBTY7s+ZEQYWxXt5RYYP9hMGWR7KUjANBgkqhkiG
# 9w0BAQEFAASCAQBujx89anbR7gaMck5ODMCj3h+rS7c3hCtqyjyXKP18mN0EBg+m
# 23ngwZq3lnuiQ9mfpnnRzNC48BK+/dZuEa0z3ot7KzZXfYUXr+4M0jInf6khO2fd
# YCR/KPlWjUKirMn4VWVzYqsVYHxZ9RYt89xaJ+fD/5xfzuwSBt2MYTkLr4jXXWqi
# vGDbfzC4LSoChTAK7TrZ9EO10YmgCRe2q3SpBuA4nuc6BGGeaypBWiea1RSXqj3G
# 9DE1NZCCNsFmmt9WQCUC8Fo3bgIwmVmpFSKc3chMb2PVn/QxNhts4KU67U5LmoON
# cYAR5EQ7Byi/LL3+MaOedwNkIdz0XJ+RBeOw
# SIG # End signature block

