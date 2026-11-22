<#
    .NOTES
    ===========================================================================
	Script name:	IISLogCleanup.ps1
    Version:    	1.1
	Created by: 	Shaun Pattillo
	Created on: 	01/04/2020
	Dependencies:	Requires -RunAsAdministrator / must run with admin privileges
    ===========================================================================
	
    .DESCRIPTION
        IIS doesn't clean up its log files nicely, so this script does 
        it periodically to prevent bugs and issues with temp files hitting max limits
        Credit to https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/cleaning-week-deleting-temp-files
        for the original script
    
    .EXAMPLE
       Runs as a scheduled task, once a day. Clears IIS logs older than X days
#>

#Script contents.
#=============================================================================

<#
.DESCRIPTION
    Delete-Files: Delete things from places based on age
.PARAMETER days
    Age of files to clear in days (default 30)
.PARAMETER location
    Location to search for files (defaults to "$env:windir\temp", $env:temp)
.PARAMETER dryrun
    Do a dryrun and don't actually delete anything (defaults to true, must explicitly pass false to delete files)
#>
Function Delete-Files
{
    param(
        [Parameter(Mandatory=$false)][int]$days = 30,
        [Parameter(Mandatory=$false)][string]$location = "$env:windir\temp", $env:temp,
        [Parameter(Mandatory=$false)][bool]$dryrun = $true
    )
     
    # look at temp files older than $days
    $cutoff = (Get-Date).AddDays(-$days)
    
    # use an ordered hash table to store logging info
    $sizes = [Ordered]@{}
    
    # find all files in $location recursively
    Get-ChildItem $location -Recurse -Force -File | 
    # calculate total size before cleanup
    ForEach-Object { 
        $sizes['TotalSize'] += $_.Length 
        $_
    } | 
    # take only outdated files
    Where-Object { $_.LastWriteTime -lt $cutoff } | 
    # try to delete. Add retrieved file size only
    # if the file could be deleted
    ForEach-Object {
      try 
      { 
        $fileSize = $_.Length

        if($dryrun){ Remove-Item -Path $_.FullName -ErrorAction SilentlyContinue -WhatIf }
        else{ Remove-Item -Path $_.FullName -ErrorAction SilentlyContinue }
        
        $sizes['Retrieved'] += $fileSize
      }
      catch {}
    }
    
    # turn bytes into MB
    $Sizes['TotalSizeMB'] = [Math]::Round(($Sizes['TotalSize']/1MB), 1)
    $Sizes['RetrievedMB'] = [Math]::Round(($Sizes['Retrieved']/1MB), 1)
    
    New-Object -TypeName PSObject -Property $sizes
}

# Clear the IIS access logs: 
$IISlogs = "C:\inetpub\logs\LogFiles"

Delete-Files -days 30 -location $IISlogs -dryrun $false