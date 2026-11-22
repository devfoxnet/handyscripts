<#
    .NOTES
    ===========================================================================
	Script name:	RegisterAllVMsInADatastore.ps1
    Version:    	1.1
	Created on: 	16/01/2020
	Dependencies:	Powershell, PowerCLI
    ===========================================================================
	
    .DESCRIPTION
		Script for registering all VMs in a specific datastore
        Useful in cases where all VMs are orphaned and must be reregistered
		THIS SCRIPT IS DANGEROUS, PLEASE RUN WITH CAUTION
        IT DOES NOT CHECK IF A VMX IS ALREADY REGISTERED
#>

#Script Variables
# The location to search for VMX files: 
$Datastores = "ExampleDatastore"

# Location to register the VMs:
$Cluster = "Cluster Name" 
$VMFolder = "Customer_VMs" 

# Provide a host which has access to the datastore we want to work on:
$ESXHost = "10.10.10.110"
$ESXHost = Get-VMHost $ESXHost

ForEach($Datastore in Get-Datastore $Datastores) 
{
    # Set up Search for .VMX Files in Datastore
    $ds = Get-Datastore -Name $Datastore | ForEach{ Get-View $_.Id }
    $SearchSpec = New-Object VMware.Vim.HostDatastoreBrowserSearchSpec
    $SearchSpec.matchpattern = "*.vmx"
    $dsBrowser = Get-View $ds.browser
    $DatastorePath = "[" + $ds.Summary.Name + "]"
    # Find all .VMX file paths in Datastore, filtering out ones with .snapshot
    $SearchResult = $dsBrowser.SearchDatastoreSubFolders($DatastorePath, $SearchSpec) | Where {$_.FolderPath -notmatch ".snapshot"} | ForEach {$_.FolderPath + ($_.File | Select Path).Path}
    # Register all .vmx Files as VMs on the datastore
    ForEach($VMXFile in $SearchResult)
    {
		Write-Host "Adding $VMXFile to cluster $Cluster"
		New-VM -VMFilePath $VMXFile -VMHost $ESXHost -Location $VMFolder 
    }
}