<#
  .NOTES
  ===========================================================================
    Script name:	VMISORemoval.ps1
    Version:    	1.0
	Created by: 	Modified version of Luc Dekens' script
	Created on: 	30/11/2020
	Dependencies:	Powershell 5 or Above, PowerCLI 11 or above and Posh-SSH installed
  ===========================================================================
	
  .DESCRIPTION
    This is a modified LucD script, so that it is able to handle VMs with multiple CD Drives - https://www.lucd.info/2015/10/02/answer-the-question/
    - You should fill out VM names in the array, in the format below.
    - There is a foreach at the bottom on the script that will run through each of the VMs in the $Vmname array.
#>

#Script Variables
#==================================================================================================================================

#VM Name array
$VmName = 'Test','Test2','vm-name','vm-02'

#Do Not Edit Anything Below This Line
#======================================================================================

function Set-CDDriveAndAnswer
{
<#
.SYNOPSIS  Unmounts a CD/DVD from a VM and answers an outstanding question
.DESCRIPTION The function will unmount a CD/DVD from a DVD.
  If the unmount causes a question, the function will answer the question.
.NOTES  Author:  Luc Dekens
.PARAMETER Name
  The DisplayName of the VM
.PARAMETER Server
  The vSphere Server on which the VM is located.
  The default is $global:defaultviserver
.EXAMPLE
  PS> Set-CDDriveAndAnswer -Name MyVM -Server $global:DefaultVIServer
.EXAMPLE
  PS> Get-VM | Set-CDDriveAndAnswer
#>
  [CmdletBinding()]
  param(
  [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
  [string[]]$Name,
  [PSObject]$Server
  )
 
  Begin
  {
    $cdQuestion = {
      param($VmName,$vServer)
    
      $maxPass = 5
      $pass = 0
    
      Connect-VIServer -Server $vServer.Name  -Session $vServer.SessionSecret | Out-Null
      while($pass -lt $maxPass){
        $question = Get-VM -Name $VmName | Get-VMQuestion -QuestionText "*locked the CD-ROM*"
        if($question){
          Set-VMQuestion -VMQuestion $question -Option button.Yes -Confirm:$false
          $pass = $maxPass + 1
        }
        $pass++
        sleep 1
       }
    }
 
    if(!$Server){
      $Server = $global:DefaultVIServer
    }
  }

  Process
	{
    $Name | ForEach {
		  $vm = Get-VM -Name $_
		  $cds = Get-CDDrive -VM $vm
		  foreach ($cd in $cds){
		  	$job = Start-Job -Name Check-CDQuestion -ScriptBlock $cdQuestion -ArgumentList $_,$Server
		  	Set-CDDrive -CD $cd -NoMedia -Confirm:$false
		  	Stop-Job $job 
			}
		}
	}
}

#=========================================================================

# Pause before removing VM ISOs
Write-Host -ForegroundColor Red "About to remove the ISOs from the following VMs, please ensure you have pings running against them:"
Echo $vmName
$safetyAnswer = Read-Host -Prompt "Do you wish to continue? (yes/no)"
if ($safetyAnswer -ne "yes")
{
  Write-Host -ForegroundColor Red "Exiting script due to safety answer."
	exit
}

# Loop through VMs specified in 'VmName' array
foreach ($vm in $vmName){
    Write-Host "Removing CD drive for: ",$vm
    Set-CDDriveAndAnswer -Name $vm
}