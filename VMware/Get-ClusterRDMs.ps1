<#
    .NOTES
    ===========================================================================
	Script name:	Get-ClusterRDMs.ps1
    Version:    	1.0
	Created on: 	04/02/2018
	Dependencies:	PowerCLI module
    ===========================================================================
	
    .DESCRIPTION
        Quick dirty one liner for finding RDMs in a cluster
    .EXAMPLE
        Get-ClusterRDMs -Cluster "ClusterName"
    .EXAMPLE
       Get-Cluster "ClusterName" | Get-ClusterRDMs
#>

function Get-ClusterRDMs
{
    param(
    [CmdletBinding()]
    [parameter(Mandatory = $true, ValueFromPipeline = $true)][String]$Cluster
    )
        Get-Cluster $Cluster | Get-VM  | Get-HardDisk | Where {"RawPhysical","RawVirtual" -contains $_.DiskType} | Select @{N="VM";E={$_.Parent.Name}},Name,ScsiCanonicalName 
}