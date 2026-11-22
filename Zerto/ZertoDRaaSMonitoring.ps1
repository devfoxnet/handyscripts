<#
    .NOTES
    ===========================================================================
	Script name:	ZertoDRaaSMonitoring.ps1
    Version:    	1.0
	Created by: 	Shaun Pattillo
	Created on: 	22/06/2020
	Dependencies:	CredentialManager
    ===========================================================================
	
    .DESCRIPTION
        Monitoring to pull VPG health info from analytics.zerto.com API 
    
    .EXAMPLE
       Run as a scheduled task, every hour
#>

#Define variables - List all variables that need setting for script to run.
$SecureCreds = Get-StoredCredential -Target "analytics.api.zerto.com"

$ZertoBaseURI = "https://analytics.api.zerto.com"
$ZertoURI = $ZertoBaseURI+"/v2"

$datestring = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

#Script contents.
#=============================================================================
# Set SSL to use TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'

function Get-AuthToken
{
    Param(
        [Parameter(Mandatory=$True)][String]$Username,
        [Parameter(Mandatory=$True)][String]$Password,
        [Parameter(Mandatory=$True)][URI]$ZertoURI = "https://analytics.api.zerto.com/v2/auth/token"
    )

    # Build request
    $Headers = @{}
    $Headers.Add("Content-Type","application/json")
    $Headers.Add("Accept","application/json")

    $Body = @{}
    $Body.Add("username",$Username)
    $Body.Add("password",$Password)
    $Body = $Body | ConvertTo-Json

    Write-Host "Validating connection to $ZertoURI" 
    try
    {
        $Request = Invoke-RestMethod -Uri $ZertoURI -Headers $Headers -Body $Body -Method 'POST'
        Write-Host "Connection Success"  -ForegroundColor Green
        Return $Request
    }
    catch
    {
        Write-Host "Connection Failed" -ForegroundColor Red
        Write-Host "$($_.Exception)" -ForegroundColor Red
        Return $false
    }
}

function Build-Headers
{
    Param(
        [Parameter(Mandatory=$True)][string]$Token
    )

    # Build headers
    $headers = @{}
    $headers.Add("Authorization","Bearer "+$Token)
    $headers.Add("Content-Type","application/json")
    $headers.Add("Accept","application/json")

    Return $headers
}

$AuthURI = $ZertoURI+"/auth/token"
$Username = $SecureCreds.UserName
$Password = $SecureCreds.GetNetworkCredential().Password

$Auth = Get-AuthToken -Username $Username -Password $Password -ZertoURI $AuthURI

if($Auth)
{
    $Token = $Auth.token
    $Headers = Build-Headers -Token $Token
    $VPGListURI = $ZertoURI+"/monitoring/vpgs"

    $Request = Invoke-RestMethod -Uri $VPGListURI -Headers $Headers -Method 'GET'
    $Request.vpgs | Select-Object -Property name,health,status,subStatus,actualRPO | FT
}
else
{
    Write-Host "Authentication failed" -ForegroundColor Red
}