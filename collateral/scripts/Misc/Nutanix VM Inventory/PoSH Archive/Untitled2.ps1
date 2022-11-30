# kees@nutanix.com
# @kbaggerman on Twitter
# http://blog.myvirtualvision.com


# Adding PS cmldets
Add-PSSnapin -Name NutanixCmdletsPSSnapin


## Steven Potrais - Connecting to the Nutanix node

Connect-NTNXCluster -Server 10.21.210.40 -UserName admin -AcceptInvalidSSLCerts

$CollAllVMs = Get-NTNXVM

