# Scripts and tips for Windows


#### Powershell Credential Manager

Stop putting credentials in your powershell scripts. Store and used them in the Windows Credential Manager instead: 
https://www.powershellgallery.com/packages/CredentialManager/2.0

`# Force TLS1.2 is sometimes needed for old boxes
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Register-PSRepository -Default -Verbose
Install-Module -Name CredentialManager
New-StoredCredential -Target "CredName" -UserName "username" -Password "***"`

See SecureCredsDemo.ps1 for practical examples. 

#### Run as user 

Useful for testing automation where your scripts may be run by Task Scheduler as a different user: 

`start powershell -credential "foo"`

#### Get last error types 

`$Error[0] | Select –Property *
$Error[0].exception.GetType().fullname`

#### Powershell grep

`Select-String -Path *.ps1 -Pattern "TextToLookFor"`

#### Find and replace a string from multiple files

`Get-ChildItem C:\mycode\project\subfolder *.ps1 | ForEach { (Get-Content $_ | ForEach { $_ -replace "OLD", "NEW" }) | Set-Content $_ }`

#### Test port connection

`Test-NetConnection -ComputerName 192.168.1.1 -Port 3033`
