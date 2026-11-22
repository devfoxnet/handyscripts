<#
    .NOTES
    ===========================================================================
	Script name:	Get-Snapshots.ps1
    Version:    	1.0
	Created on: 	20/11/2023
	Dependencies:	VMware Modules
					Requires Powershell 5 or Above, PowerCLI 11 or above
    ===========================================================================
	
    .DESCRIPTION
        Get all snapshots in a vCenter older than X days
    .PARAMETER SnapAge
        Snaps older than this will be returned. 3 days is best practice
    .PARAMETER ExcludeVMs
        String array of VMs to exclude, things like citrix gold images. Default: empty
    .PARAMETER vCenter
        Specify a vCenter connection object. Default: $global:DefaultVIServer
    .EXAMPLE
       Get-Snapshots -SnapAge 3 -ExcludeVMs $excludeArray -vCenter $vclink
    .EXAMPLE
        Get-Module -ListAvailable VMware* | Import-Module
        .\Get-Snapshots.ps1
        $vclink = Connect-VIServer -Server "myvcenter.domain.com"
        $excludeArray = @("CitrixGold-A","CitrixGold-B","CitrixGold-C")
        $snaps = Get-Snapshots -SnapAge 3 -ExcludeVMs $excludeArray -vCenter $vclink
#>

Function Get-Snapshots 
{
  param(
  [CmdletBinding()]
  [parameter(Mandatory = $true)][int]$SnapAge,
  [parameter(Mandatory = $false)][string[]]$ExcludeVMs = @(),
  [parameter(Mandatory = $false)][VMware.VimAutomation.ViCore.Util10.VersionedObjectImpl]$vCenter = $global:DefaultVIServer
  )
    try
    {
        $now = Get-Date
        [regex] $excludeRgx = ( $ExcludeVMs | ForEach {[regex]::escape($_)} ) -join “|”
        # Exlude default veeam replicas which end with "*_replica" by default
        $oldSnaps = Get-View -ViewType VirtualMachine -Property Name,Snapshot -Filter @{ "snapshot" = "" } -Server $vCenter | Where-Object { $_.Name -notlike "*_replica" } | 
                Where-Object { $_.Name -NotMatch $excludeRgx } | ForEach-Object { Get-VM -Id $_.moref } | Get-Snapshot | Where-Object { ($now - $_.Created).Days -ge $SnapAge } | 
                Select-Object VM, Created, Description, SizeGB

	    $consolSnaps = Get-View -ViewType VirtualMachine -Property Name,"RunTime" -Server $vCenter | Where-Object { $_.Runtime.ConsolidationNeeded } | Select-Object @{ Name = "VM"; Expression = { $_.Name } }
	    $oldSnaps = $oldSnaps + $consolSnaps

        Return $oldSnaps
    }
    catch
    {
        Write-Host Error occured in script: -ForegroundColor Red
        Write-Host $_
        Write-Host $_.ScriptStackTrace
    }
}
