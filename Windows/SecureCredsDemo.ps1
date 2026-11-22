<#
    .NOTES
    ===========================================================================
	Script name:	SecureCredsDemo.ps1
    Version:    	1.0
	Created by: 	Shaun Pattillo
	Created on: 	21/01/2026
	Dependencies:	https://www.powershellgallery.com/packages/CredentialManager/2.0
                    VCF.PowerCLI
    ===========================================================================
	
    .DESCRIPTION
        Example of using securecreds module to connect to a vCenter without 
        having plaintext creds in the script
#>

#Script contents.
#=============================================================================

# Get the cred manager if you don't already have it: 
#Install-Module -Name CredentialManager

# Get the powerCLI tools - NB: broadcom changed the name recently:
#Install-Module -Name VCF.PowerCLI

# Import the VMware modules
Get-Module -ListAvailable VMware* | Import-Module

# Ignore self-signed SSL on our vCenter
Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false

$vCenterURL = "vcenter.mydomain.org"

# Add the creds you will be using as a Generic Credential in Control Panel > Credential Manager 
# This line will import them from Credential Manager as a PSCredential object with the password 
# saved encrypted as System.Security.SecureString
$SecureCreds = Get-StoredCredential -Target "vcenter.mydomain.org"

Write-Host Connecting to $vCenterURL -ForegroundColor Green
try
{
    # Most powershell cmdlets will accept the PSCredential object so you never need to have the 
    # password decrypted at any point in the script run. 
    # NB: using the -Credential param, not the -User / -Password params! 
    $vclink = Connect-VIServer -Server $vCenterURL -Credential $SecureCreds

    # Do your script stuff
    Get-VMHost | FT
}
catch
{
    Write-Host Error occured in script while connecting to $vCenterURL -ForegroundColor Red
    Write-Host $_
    Write-Host $_.ScriptStackTrace
}
finally
{
    # Clean up connections
    Disconnect-VIServer -Confirm:$false -Server $vclink
}

# If you need to extract the creds as plaintext for any reason, it is possible to do so. 
# Be careful with this as you do risk exposing password in plain text!
# But it is still more secure than leaving creds open in the code.

# For example here, a Zerto API using basic auth wants the creds formatted in a specific way.
# Note that the creds are converted to base64 and sent over https (self-signed but still https)
<#
$ZertoURI = "https://zerto-zvm.mydomain.org:9669/v1/session/add"
$SecureCredsZerto = Get-StoredCredential -Target "zerto-zvm.mydomain.org"
$Username = $SecureCredsZerto.UserName
$Password = $SecureCredsZerto.GetNetworkCredential().Password

$AuthInfo = ("{0}:{1}" -f $Username,$Password)
$AuthInfo = [System.Text.Encoding]::UTF8.GetBytes($AuthInfo)
$AuthInfo = [System.Convert]::ToBase64String($AuthInfo)

$Headers = @{Authorization=("Basic {0}" -f $AuthInfo)}
$ContentType = "application/json"
$Body = @{}

$code= @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
Add-Type -TypeDefinition $code -Language CSharp
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

try
{
    $Request = Invoke-WebRequest -Uri $ZertoURI -Method 'POST' -Headers $Headers -ContentType $ContentType -Body $Body -Verbose
    Write-Host "Connection Success"  -ForegroundColor Green
}
catch
{
    Write-Host "Connection Failed" -ForegroundColor Red
    Write-Host "$($_.Exception)" -ForegroundColor Red
}
#>
