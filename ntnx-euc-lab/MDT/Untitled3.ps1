 
 
 
     While ($$_.ExtensionData.Runtime.PowerState -eq "poweredOn")   {
         Start-Sleep -Seconds 2
         $vm.ExtensionData.UpdateViewData("Runtime.PowerState")

     }
    Try {

          $DateTime = Get-Date

          New-Snapshot -VM $_ -Name $DateTime
     }

     Catch {

          throw (New-Object System.Exception(“Take VM Snapshot failed.”,$_.Exception))

     }