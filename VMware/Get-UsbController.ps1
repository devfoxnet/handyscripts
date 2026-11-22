<#
    .NOTES
    ===========================================================================
    Script name:	Get-UsbController.ps1
    Version:    	1.0
    Dependencies:	PowerCLI 
    ===========================================================================

    .DESCRIPTION
      Get-UsbDevice only returns connected devices. To see controllers you need to go digging: 
      Look in $VM.ExtensionData.Config.Hardware.Device
      for objects of type VMware.Vim.VirtualUSBController (USB 2.0) or
      VMware.Vim.VirtualUSBXHCIController (USB 3.0)
#> 

function Get-UsbController{
  param(
  [CmdletBinding()]
  [parameter(Mandatory = $true, ValueFromPipeline = $true)]
  [PSObject[]]${VM}
  )

  process{
    foreach($vmObj in $vm){
      if($vmObj -is [System.String]){
        $vmObj = Get-VM -Name $vmObj
      }
      $vmObj.ExtensionData.Config.Hardware.Device |
      Where {$_ -is [VMware.Vim.VirtualUSBController] -or $_ -is [VMware.Vim.VirtualUSBXHCIController]} | ForEach-Object{
        New-Object PSObject -Property @{
          VM = $vmObj.Name
          Name = $_.DeviceInfo.Label
          Summary = $_.DeviceInfo.Summary
          AutoConnectDevices = $_.AutoConnectDevices
          EhciEnabled = $_.EhciENabled
          BusNumber = $_.BusNumber
          UnitNumber = $_.UnitNumber
        }
      }
    }
  }
}