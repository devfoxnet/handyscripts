<#
    .NOTES
    ===========================================================================
	Script name:	Get-ZertoVPG-ZVMAPI.ps1
    Version:    	0.4
	Created by: 	Shaun Pattillo
	Created on: 	05/10/2023
	Dependencies:	CredentialManager
    ===========================================================================
	
    .DESCRIPTION
        Monitoring to pull VPG health info from ZVM API
    
    .EXAMPLE
#>

#Define variables - List all variables that need setting for script to run.
$SecureCreds = Get-StoredCredential -Target "zerto-zvm.mydomain.org"

$ZertoBaseURI = "https://zerto-zvm.mydomain.org:9669"
$ZertoURI = $ZertoBaseURI+"/v1"

$datestring = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

#Script contents.
#=============================================================================
# Set SSL to use TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'

#Ignore SSL Warning for self signed certs
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

function Get-AuthToken
{
    Param(
        [Parameter(Mandatory=$True)][String]$Username,
        [Parameter(Mandatory=$True)][String]$Password,
        [Parameter(Mandatory=$True)][URI]$ZertoURI = "https://zerto-zvm.mydomain.org:9669/v1/session/add"
    )

    # Build request
    $AuthInfo = ("{0}:{1}" -f $Username,$Password)
    $AuthInfo = [System.Text.Encoding]::UTF8.GetBytes($AuthInfo)
    $AuthInfo = [System.Convert]::ToBase64String($AuthInfo)

    $Headers = @{Authorization=("Basic {0}" -f $AuthInfo)}
    $ContentType = "application/json"
    $Body = @{}

    Write-Host "Validating connection to $ZertoURI" 
    
    try
    {
        $Request = Invoke-WebRequest -Uri $ZertoURI -Method 'POST' -Headers $Headers -ContentType $ContentType -Body $Body -Verbose
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

$AuthURI = $ZertoURI+"/session/add"
$Username = $SecureCreds.UserName
$Password = $SecureCreds.GetNetworkCredential().Password

$Auth = Get-AuthToken -Username $Username -Password $Password -ZertoURI $AuthURI

if($Auth)
{
    $ZertoToken = $Auth.headers.get_item("x-zerto-session")
    $Headers = @{"x-zerto-session" = $ZertoToken} 

    Write-Host "All VPGs"
    $VPGListURI = $ZertoURI+"/vpgs"
    $Request = Invoke-RestMethod -Uri $VPGListURI -Headers $Headers -Method 'GET'
    $Request | Select VpgName, ConfiguredRpoSeconds, ActualRPO, AlertStatus | FT

    Write-Host "One VPG by VpgIdentifier"
    $VPGSingleURI = $ZertoURI+"/vpgs/<put vpg ID here>"
    $Request = Invoke-RestMethod -Uri $VPGSingleURI -Headers $Headers -Method 'GET'
    $Request

    Write-Host "VPG by Name"
    $VPGName = "PutVPGNameHere"
    $VPGByNameURI = $ZertoURI+"/vpgs?name=$VPGName"
    $Request = Invoke-RestMethod -Uri $VPGByNameURI -Headers $Headers -Method 'GET'
    $Request

}
else
{
    Write-Host "Authentication failed" -ForegroundColor Red
}
