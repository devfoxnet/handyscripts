# Scripts and tips for Windows

### Powershell Credential Manager

Stop putting credentials in your powershell scripts. Store and used them in the Windows Credential Manager instead: 
https://www.powershellgallery.com/packages/CredentialManager/2.0

```powershell
# Force TLS1.2 is sometimes needed for old boxes
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Register-PSRepository -Default -Verbose
Install-Module -Name CredentialManager
New-StoredCredential -Target "CredName" -UserName "username" -Password "***"
```

See *SecureCredsDemo.ps1* for practical examples. 

### Useful automation things 

Running regular scripts using Task Scheduler can be handy, these are things I've found useful for that:

##### Run as user 

Useful for testing automation where your scripts may be run by Task Scheduler as a different user: 

```powershell
start powershell -credential "foo"
```

##### PsExec run as system user

`PsExec.exe -s -i cmd.exe`

##### Task Scheduler Exit Codes / permission issues

Pass the last exit code back up so it shows up in the Task Scheduler history, and execute scripts without profiles: 

```powershell
C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe -NoProfile -NoProfile -ExecutionPolicy Bypass -Command  ". C:\scritps\myscript.ps1; exit $LASTEXITCODE"
```

##### Get last error types 

```powershell
$Error[0] | Select –Property *
$Error[0].exception.GetType().fullname
```

### Useful One Liners:

#### Powershell grep

```powershell
Select-String -Path *.ps1 -Pattern "TextToLookFor"
```

#### Find and replace a string from multiple files

```powershell
Get-ChildItem C:\mycode\project\subfolder *.ps1 | ForEach { (Get-Content $_ | ForEach { $_ -replace "OLD", "NEW" }) | Set-Content $_ }
```

#### Test port connection
On boxes where Test-NetConnection isn't available, Test-Port.ps1 may work. 
```powershell
Test-NetConnection -ComputerName 192.168.1.1 -Port 3033
```
