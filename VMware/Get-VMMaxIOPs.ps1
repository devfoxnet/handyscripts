<#
    .NOTES
    ===========================================================================
	Script name:	Get-VMIOPs.ps1
    Version:    	1.0
	Created by: 	Shaun Pattillo
                    Based on scripts from William Lam
	Created on: 	12/06/2024
	Dependencies:	VMware Modules
					Requires Powershell 5 or Above, PowerCLI 11 or above
    ===========================================================================
	
    .DESCRIPTION
       Checks IOPs caps and max IO over last 24h for all VMs on a datastore
#>

Function Get-VMMaxIOPs {
    <#  
    .SYNOPSIS
    	 Checks IOPs caps and max IO over last 24h for all VMs or per datastore
    .DESCRIPTION
        Checks IOPs caps and max IO over last 24h for all VMs or per datastore
    .PARAMETER datastoreName
        Restrict search to VMs on a specific datastore, defaults to all 
    .PARAMETER hoursBack
        Hours back to look for peak IO, defaults to 24
    .PARAMETER Server
    	Specify the vCenter to connect to, defaults to $defaultVIServer
    #>
    param(
         [Parameter(Mandatory=$false)][String]$datastoreName = $null,
         [Parameter(Mandatory=$false)][String]$hoursBack = '24',
         [Parameter(Mandatory = $false)][VMware.VimAutomation.ViCore.Util10.VersionedObjectImpl]$Server = $defaultVIServer
         )
    try
    {    
        if($datastoreName -eq $null) 
        {
            $vms = Get-Vm -Server $vclink
        } 
        else 
        {
        $vms = Get-Datastore -Name $datastoreName -Server $vclink | Get-Vm
        }


        # Get-Stat to find Max IOPS/sec on VMs
        # Value is the max IO in the 24 hours
        # Based on http://www.lucd.info/2011/04/22/get-the-maximum-iops/
        
        $PoweredOnvms = $vms | where {$_.PowerState -eq "PoweredOn"}
        
        $metrics = "disk.numberwrite.summation","disk.numberread.summation"
        $start = (Get-Date).AddHours(-$hoursBack)
        $stats = Get-Stat -Realtime -Stat $metrics -Entity $PoweredOnvms -Start $start 
        $interval = $stats[0].IntervalSecs
        
        $lunTab = @{}
        foreach($ds in (Get-Datastore -VM $PoweredOnvms | where {$_.Type -eq "VMFS"})){
        	$ds.ExtensionData.Info.Vmfs.Extent | %{
        		$lunTab[$_.DiskName] = $ds.Name
        	}
        }
         
        $report = $stats | Group-Object -Property {$_.Entity.Name}, Instance | %{
            New-Object PSObject -Property @{    VM = $_.Values[0]
         		                                Disk = $_.Values[1]
         		                                IOPSMax = ($_.Group | `
         		                                	      Group-Object -Property Timestamp | `
         		                                	      %{$_.Group[0].Value + $_.Group[1].Value} | `
         		                                	      Measure-Object -Maximum).Maximum / $interval
        		                                Datastore = $lunTab[$_.Values[1]]   }
        }
    }
    catch
    {
        Write-Host Error occured in script get-vmiops
        Write-Host $_
        Write-Host $_.ScriptStackTrace
    }
    finally
    {
        Write-Host "Max IO in last " $hoursBack " hours"
        $report | Sort-Object -Descending IOPSMax | ft
        Disconnect-VIServer -Confirm:$false -Server $vclink
    }
}

Function Get-VmDiskIOLimits {
    <#  
    .SYNOPSIS
    	 Checks IOPs caps all VMs or per datastore
    .DESCRIPTION
        Checks IOPs caps all VMs or per datastore
    .PARAMETER datastoreName
        Restrict search to VMs on a specific datastore, defaults to all 
    .PARAMETER Server
    	Specify the vCenter to connect to, defaults to $defaultVIServer
    #>
    param(
         [Parameter(Mandatory=$false)][String]$datastoreName = $null,
         [Parameter(Mandatory = $false)][VMware.VimAutomation.ViCore.Util10.VersionedObjectImpl]$Server = $defaultVIServer
         )
    try
    {    
        if($datastoreName -eq $null) 
        {
            $vms = Get-Vm -Server $vclink
        } 
        else 
        {
        $vms = Get-Datastore -Name $datastoreName -Server $vclink | Get-Vm
        }

        $results = @()
    
        # Get the IOPs limits per VM
        foreach ($vm in $vms | Sort-Object -Property Name) 
        {
            $DiskIOPs = ($vm | Get-VMResourceConfiguration).DiskResourceConfiguration.DiskLimitIOPerSecond
            $tmp = [pscustomobject] @{  VM = $vm.Name;
        			                    IOPs = $DiskIOPs; }
            $results+=$tmp
        } 
    }
    catch
    {
        Write-Host Error occured in script
        Write-Host $_
        Write-Host $_.ScriptStackTrace
    }
    finally
    {
        Write-Host "IO Limits report (-1 = no limit)"
        $results 
    }
}

# Run script:
$vclink = Connect-VIServer -Server myvcenter.mydomain.org

Get-VMMaxIOPs -datastoreName 'MyDatastore' -Server $vclink
Get-VmDiskIOLimits -datastoreName 'MyDatastore' -Server $vclink

Disconnect-VIServer -Confirm:$false -Server $vclink
