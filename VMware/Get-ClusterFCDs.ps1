<#
  .NOTES
    ===========================================================================
    Script name:	Get-ClusterFCDs.ps1
    Version:    	1.0
    Created on: 	25/08/2023
    Dependencies:	Requires Powershell 5 or Above, PowerCLI 11 or above
    ===========================================================================
	
  .DESCRIPTION
    One-liner for finding clusters in using FDCs rather than RDMs
  .PARAMETER ClusterName
    The name of the Cluster to search for Shared FCDs
  .EXAMPLE
    Get-ClusterFCDs -ClusterName NAME
  .EXAMPLE
    Get-Cluster -Name NAME | Get-ClusterFCDs
#>

function Get-ClusterFCDs
{
  param(
    [CmdletBinding()]
    [parameter(Mandatory = $true, ValueFromPipeline = $true)] [String]$ClusterName
  )
    Get-Cluster $ClusterName | Get-VM | Get-ScsiController | Where {$_.BusSharingMode -ne "NoSharing"} | Select @{N="Instance ID";E={$_.Parent.Name}}, @{N="VPC ID";E={$_.parent.resourcepool}}, @{N="Used space GB";E={$_.parent.UsedSpaceGB.ToString("F2")}} | FT -autosize
}