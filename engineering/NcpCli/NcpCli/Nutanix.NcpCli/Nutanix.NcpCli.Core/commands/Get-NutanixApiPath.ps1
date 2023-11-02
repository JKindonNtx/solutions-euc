function Get-NutanixApiPath {

<#
    .SYNOPSIS
    Builds the Nutanix Api Path.

    .DESCRIPTION
    This function will take in a value and build the Nutanix Api Path based on the version of the Api being used.
    
    .PARAMETER NameSpace
    Specifies the Api NameSpace

    .INPUTS
    This function will take inputs via pipeline as string

    .OUTPUTS
    Returns an object with the relevant Api Path

    .EXAMPLE
    PS> Get-NutanixApiPath -NameSpace "Tasks" 
    Builds the ApiPath for the NameSpace Tasks.

    .LINK
    https://github.com/nutanix-enterprise/solutions-euc/blob/main/engineering/NcpCli/Help/Get-NutanixApiPath.md
#>

    [CmdletBinding()]

    Param (
        [Parameter(ValuefromPipelineByPropertyName = $true,mandatory=$true)][System.String]$NameSpace,
        $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
    )

    begin {

        # Set strict mode and initial return value
        Set-StrictMode -Version Latest

    } # begin

    process {

        # Build Api Path from NameSpace passed into the function
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Building Api Path for $($NameSpace)"
        switch ($NameSpace)
        {
            # Nutanix AIOps NameSpace
            "AIOps.Sources" { $Return = "/api/aiops/v4.0.a2/stats/sources" }
            "AIOps.Entities" { $Return = "/api/aiops/v4.0.a2/stats/sources/{SourceExtID}/entity-types" }
            "AIOps.Metadata" { $Return = "/api/aiops/v4.0.a2/stats/sources/{SourceExtID}/entity-descriptors" }
            "AIOps.Timeline" { $Return = "/api/aiops/v4.0.a2/stats/sources/{SourceExtID}/entities/{EntityExtID}" }
            # Nutanix Cluster Management NameSpace
            "Cluster.SNMP" { $Return = "/api/clustermgmt/v4.0.b1/config/clusters" }  
            "Cluster.SysLog" { $Return = "/api/clustermgmt/v4.0.b1/config/clusters" }  
             
            "Cluster.Host" { $Return = "/api/clustermgmt/v4.0.b1/config" }  
            "Cluster.HostNIC" { $Return = "/api/clustermgmt/v4.0.b1/config/clusters" }  
            "Cluster.HostVirtualNIC" { $Return = "/api/clustermgmt/v4.0.b1/config/clusters" }  
            "Cluster.Stats" { $Return = "/api/clustermgmt/v4.0.b1/stats/clusters" }  
            # Nutanix LCM NameSpace
            "LCM.Status" { $Return = "/api/lcm/v4.0.a1/resources/status" }
            "LCM.Images" { $Return = "/api/lcm/v4.0.a1/resources/images" }
            "LCM.Bundles" { $Return = "/api/lcm/v4.0.a1/resources/bundles" }
            "LCM.Entity" { $Return = "/api/lcm/v4.0.a1/resources/entities" }
            "LCM.History" { $Return = "/api/lcm/v4.0.a1/resources/history" }
            "LCM.ModuleConfig" { $Return = "/api/lcm/v4.0.a1/resources/moduleConfig" }
            "LCM.Config" { $Return = "/api/lcm/v4.0.a1/resources/config" }
            "LCM.NodePriorityConfig" { $Return = "/api/lcm/v4.0.a1/resources/config/node-priorities" }
            # Nutanix Prism NameSpace
            "Prism.Alert" { $Return = "/api/prism/v4.0.a2/serviceability/alerts" }
            "Prism.Policy" { $Return = "/api/prism/v4.0.a2/serviceability/alerts/system-defined-policies" }
            "Prism.UserPolicy" { $Return = "/api/prism/v4.0.a2/serviceability/alerts/user-defined-policies" }
            "Prism.Event" { $Return = "/api/prism/v4.0.a2/serviceability/events" }
            "Prism.Audit" { $Return = "/api/prism/v4.0.a2/serviceability/audits" }
            "Prism.Task" { $Return = "/api/prism/v4.0.a2/config/tasks" }
            "Prism.Category" { $Return = "/api/prism/v4.0.a1/config/categories" }
            # Nutanix VMM NameSpace
            "VMM.VM" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMConfig" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMNGTConfig" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMCdRom" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMCdRomConfig" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMDisk" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMDiskConfig" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMGPU" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMGPUConfig" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMNIC" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMNICConfig" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMSerial" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.VMSerialConfig" { $Return = "/api/vmm/v4.0.a1/ahv/config/vms" }
            "VMM.ESXiVM" { $Return = "/api/vmm/v4.0.a1/esxi/config/vms" }
            "VMM.ESXiVMConfig" { $Return = "/api/vmm/v4.0.a1/esxi/config/vms" }
            "VMM.ESXiVMNGTConfig" { $Return = "/api/vmm/v4.0.a1/esxi/config/vms" }
            "VMM.VMTemplates" { $Return = "/api/vmm/v4.0.a1/templates" }
            "VMM.VMImages" { $Return = "/api/vmm/v4.0.a1/images" }
            "VMM.VMImageLocation" { $Return = "/api/vmm/v4.0.a1/images" }
            "VMM.VMImageCategories" { $Return = "/api/vmm/v4.0.a1/images" }
            "VMM.VMImagePlacementPolicies" { $Return = "/api/vmm/v4.0.a1/images/placement-policies" }
            "VMM.VMImageRateLimit" { $Return = "/api/vmm/v4.0.a1/images/rate-limits" }
            # Nutanix Storage NameSpace
            "Storage.Container" { $Return = "/api/storage/v4.0.a3/config/storage-containers" }
            "Storage.ContainerAttributes" { $Return = "/api/storage/v4.0.a3/config/storage-containers" }
            "Storage.DataStore" { $Return = "/api/storage/v4.0.a3/config/storage-containers/datastores" }
            # Nutanix Data Protection NameSpace
            "DP.ConsistencyGroup" { $Return = "/api/dataprotection/v4.0.a4/config/consistency-groups" }
            # Nutanix Flow NameSpace
            "Flow.ServiceGroup" { $Return = "/api/microseg/v4.0.a1/config/service-groups" }
            "Flow.NetworkSecurityPolicy" { $Return = "/api/microseg/v4.0.a1/config/policies" }
            "Flow.AddressGroup" { $Return = "/api/microseg/v4.0.a1/config/address-groups" }
            Default { $Return = "none"}
        }

    } # process

    end {

        # Return Api Path
        write-verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) - Returning Api Path $($Return)"
        return $Return

    } # end

}
