<#
    .NOTES
    ===========================================================================
	Script name:	snmptest.ps1
    Version:    	1.0
    Created by: 	Shaun Pattillo
	Created on: 	04/02/2025
	Dependencies:	Powershell
    ===========================================================================

    .DESCRIPTION
    Example commands to quickly test SNMP using built in Windows objects
    https://learn.microsoft.com/en-us/windows-hardware/drivers/print/isnmp-automation-interface
#>

$snmp = New-Object -ComObject olePrn.OleSNMP

try {
    $snmp.Open('192.168.1.1','bstrCommunity',2,1000)
    $snmp.GetTree('.1.3.6.1.2.1.1.1')
    $snmp.GetList('.1.3.6.1.4.1.24681.1.2.17.2')
    $snmp.Get('.1.3.6.1.4.1.24681.1.2.16.0')
}
catch {
    Write-Host Error occured
    Write-Host $_
    Write-Host $_.ScriptStackTrace
}
finally {
    $snmp.Close()
}
