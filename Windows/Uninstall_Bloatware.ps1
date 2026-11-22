<#
    .NOTES
    ===========================================================================
	Script name:	Uninstall_Bloatware.ps1
    Version:    	1.0
	Dependencies:	None
    ===========================================================================

    .DESCRIPTION
        Quick scipt to automate removing a list of software from OEM boxes
        Currently set up to remove all the bloat from dell boxes
#>

$applications = @(
    'Dell Display Manager',
    'Dell Display and Peripheral Manager'
    'Dell Connected Service Delivery'
    'Dell Optimizer'
    'Dell Digital Delivery Service'
    'Dell Digital Delivery'
    'Dell Core Services'
    'Dell Command'
    'Dell Backup and Recovery'
    'Alienware Command Center Suite'
    'Dell Peripheral Manager'
    'Dell Display Manager'
    'Dell Support Assistant'
    'Dell SupportAssist'
    )

foreach ($application in $applications)
{ 
    $installed = Get-Package -Name $application
    if ($installed -ne $null)
    {
        Uninstall-Package -Name $installed.Name
        Write-Host "Uninstalled $installed"
    }
}
