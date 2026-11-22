<#
    .NOTES
    ===========================================================================
	Script name:	Clear-DRSRules.ps1
    Version:    	0.1
	Created by: 	Shaun Pattillo
	Created on: 	18/02/2026
	Dependencies:	VMware Modules
					Requires Powershell 5 or Above, PowerCLI 11 or above
    ===========================================================================
	
    .DESCRIPTION
        Audit and bin off empty DRS rules
#>
Get-Module -ListAvailable VMware* | Import-Module

# Add the creds you will be using as a Generic Credential in Control Panel > Credential Manager 
# This line will import them from Credential Manager as a PSCredential object with the password 
# saved encrypted as System.Security.SecureString
$SecureCreds = Get-StoredCredential -Target "vcenter.mydomain.org"

Write-Host Connecting to vCenter
$vclink = Connect-VIServer -Server "vcenter.mydomain.org" -Credential $SecureCreds

$clusters = @("MyCluster1", "MyCluster2")

$ToDeleteDRSRules = @()

ForEach( $cluster in $clusters )
{
    # Clear the VMHostRules rules first - NB this does not include VM affinity rules!
    $DRSRules = Get-Cluster $cluster | Get-DrsVMHostRule
    ForEach( $DRSRule in $DRSRules )
    {
        # If the rule is empty, no VM, no hosts, 100% it's not in use
        if ( !$($DRSRule.VMGroup.Member) -And !$($DRSRule.VMHostGroup.Member) )
        {
            Write-Host "Rule $($DRSRule.Name) is empty, deleting" -ForegroundColor Green
            $ToDeleteDRSRules += $DRSRule
            # REVIEW THE RULES BEFORE UNCOMMENTING TO REMOVE THEM
            #Remove-DrsVMHostRule -Rule $DRSRule -Server $vclink -Confirm:$false
        }
        # If the rule is has no VM, OR no host, it's unlikely to be in use but spot-check
        elseif ( !$($DRSRule.VMGroup.Member) -Or !$($DRSRule.VMHostGroup.Member)) {
            Write-Host "Rule $($DRSRule.Name) has a host but no VM members, delete" -ForegroundColor Yellow
            $ToDeleteDRSRules += $DRSRule
            # REVIEW THE RULES BEFORE UNCOMMENTING TO REMOVE THEM
            #Remove-DrsVMHostRule -Rule $DRSRule -Server $vclink -Confirm:$false
        }
        else{
            #Write-Host "Rule $($DRSRule.Name) has a VM and a host, it's doing something, manual check" -ForegroundColor White
        }
    }

    # Empty objects are 100% not in use: 
    $emptyGroups = Get-DrsClusterGroup | Where {$_.Member.count -eq 0}
    # REVIEW THE RULES BEFORE UNCOMMENTING TO REMOVE THEM
    #$emptyGroups | Remove-DrsClusterGroup

    #Then the VM groups which are not in a rule
    $allVMGroups = Get-DrsClusterGroup -Cluster $cluster | Where-Object { $_.GroupType -eq "VMGroup" }
    # Identify unused groups
    $unusedGroups = $allVMGroups | Where-Object { $_.Name -notin $DRSRules.VMGroup.Name }
    Write-Host $cluster - VM groups which are not in a rule: $unusedGroups.Count -ForegroundColor Yellow
    # REVIEW THE RULES BEFORE UNCOMMENTING TO REMOVE THEM
    #$unusedGroups | ft
    #$unusedGroups | Remove-DrsClusterGroup

    #Finally host groups which are not in a rule
    $allVMHostGroup = Get-DrsClusterGroup -Cluster $cluster | Where-Object { $_.GroupType -eq "VMHostGroup" }
    $unusedHostGroups = $allVMHostGroup | Where-Object { $_.Name -notin $DRSRules.VMHostGroup.Name }
    Write-Host $cluster - Host groups which are not in a rule: $unusedHostGroups.Count -ForegroundColor Yellow
    # REVIEW THE RULES BEFORE UNCOMMENTING TO REMOVE THEM
    #$unusedHostGroups | ft
    #$unusedHostGroups | Remove-DrsClusterGroup
}

Disconnect-VIServer -Confirm:$false -Server $vclink
Write-Host Disconnected from vCenter
