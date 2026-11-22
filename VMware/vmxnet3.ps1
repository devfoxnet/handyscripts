<#
  .NOTES
  ===========================================================================
    Script name:	vmxnet3.ps1
    Version:    	1.0
	Created by: 	Shaun Pattillo
	Created on: 	30/11/2020
	Dependencies:	Powershell 5 or Above, PowerCLI 11 or above and Posh-SSH installed
  ===========================================================================

  .DESCRIPTION
    Quickly and dirty way to change a vNIC over to vmxnet3
    Not the recommended way (which is to remove the old NIC and add a new one)
    but I have done this once or twice
#>

Get-Module -ListAvailable VMware* | Import-Module
$SecureCredsVC = Get-StoredCredential -Target "vcenter.mydomain.org"
$vclink = Connect-VIServer -Server "vcenter.mydomain.org" -Credential $SecureCredsVC

Get-VM -Name "MyVmName" | Get-NetworkAdapter | Set-NetworkAdapter -type "vmxnet3"


Disconnect-VIServer -Confirm:$false -Server $vclink
