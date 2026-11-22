<#
    .NOTES
    ===========================================================================
	Script name:	Test-Port.ps1
    Version:    	2.1
	Created by: 	Shaun Pattillo
	Created on: 	01/10/2021
	Dependencies:	None
    ===========================================================================
#>

function Test-Port
{
<#    
    .DESCRIPTION
        Test a connection to a port using only built in windows components
        Handy on old boxes where Test-NetConnection isn't available
    .EXAMPLE
        Test-Port -IP '45.84.23.251' -Port 9392
    .SYNOPSIS
        Test a port
#>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)][string]$IP,
        [Parameter(Mandatory=$True)][string]$Port
    )
    
    try
    {
        # Test script with known good local server/port
        if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
        {
            $localhost = [System.Net.Dns]::GetHostName()
            $testclient = New-Object Net.Sockets.TcpClient
            $testclient.Connect($localhost, 80)
            Write-Verbose "Test to localhost good? - $($testclient.Connected)"
            $testclient.Dispose()
        }

        $client = New-Object Net.Sockets.TcpClient
        $client.Connect($IP, $Port)
        Write-Host "Connected to $IP on $Port" -ForegroundColor Green

        Return $true
    }
    catch
    {
        Write-Host "Error:" -ForegroundColor Red
        $_.Exception.Message
        $_.exception.innerexception

        Return $false
    }
    finally
    {
        $client.Dispose()
    }
}

$test = Test-Port -IP '192.168.1.1' -Port 9392 -Verbose
$test 
