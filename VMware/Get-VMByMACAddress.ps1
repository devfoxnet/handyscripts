<#
    .NOTES
    ===========================================================================
    Script name:	Get-VMByMACAddress.ps1
    Version:    	1.0
    Dependencies:	PowerCLI, vCenter connection
    ===========================================================================

    .DESCRIPTION
      Find a VM based on MAC address

    .EXAMPLE
      Get-VMByMACAddress -MAC "50:00:00:00:00:01"
#>

#Parameters
param(
  [Parameter(Mandatory=$true)][String]$MAC
)

Get-View -Viewtype VirtualMachine -Property Name, Config.Hardware.Device | ForEach-Object `
{
    $check = $_.Config.Hardware.Device | Where-Object { ($_ -is [VMware.Vim.VirtualEthernetCard]) -and $_.MacAddress -eq $MAC }
    if ($check)
    {
        $_.Name
    }
}
