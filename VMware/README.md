# Useful commands for VMware troubleshooting

## ESXi hosts

#### services.sh restart with logs shown

`services.sh restart &tail -f /var/log/jumpstart-stdout.log`

#### Inodes full on ESXi host: 
If Inodes on a host run out, it can cause issues with any operation that opens or edits a file. You might see errors like vmodl.fault.SystemError or Error interacting with configuration file. 

Run on SSH: 
`localcli system visorfs ramdisk list`

Check Maximum Inodes vs Used Inodes. Usually it`ll be due to SNMP trap files on the /var filesystem. Those can be cleared with the following : 
```
cd /var/spool/snmp
for i in $(ls | grep trp); do rm -f $i;done
```

#### Tmp full on NSX-T enabled host: 
NSX metrics can sometimes fill up the tmp filesystem. Check by running:
`vdf -h`
and looking at the Ramdisk section. 
Cleanup of the old metrics can be done by: 
`find /tmp/_osdata*/log/nsx/metrics/proto* -mmin +1500 -exec rm {} \;`

## vCenter applicance

#### VCSA logs filling 
https://kb.vmware.com/s/article/83671
```
du /storage/log/vmware | sort -rn | head 
truncate -s 5000 /storage/log/vmware/vmware-sps/sps-runtime.log.stderr
truncate -s 5000 /storage/log/vmware/vmafd/vmafdd.log
```

Find and removed DRM dump archived logs older than 1 year: 
`find /storage/log/vmware/vpxd/drmdump -type f -name "Plmt-*.log.gz" -mtime +365 -exec rm -f {} \;`

#### Get RDMs from VCE
Find RDM disks that need to be treated with care before storage vmotions or migrations. 
```powershell
Connect-Viserver ServerName -User x

Get-Cluster MyCluster | Get-VM | Get-HardDisk | Where {"RawPhysical","RawVirtual" -contains $_.DiskType} | Select @{N="VM";E={$_.Parent.Name}}, Name, ScsiCanonicalName 
```
#### VM by MAC Address

```powershell
Get-View -Viewtype VirtualMachine -Property Name, Config.Hardware.Device | % `
{
    $check = $_.Config.Hardware.Device | ? { ($_ -is [VMware.Vim.VirtualEthernetCard]) -and $_.MacAddress -eq "00.50.56.8e.06.fc" }
   if ($check)
    {
        $_.Name
    }
}
```

#### VMFS5 iSCSI unmap 
Manually unmap storage on an old VMFS5 datastore:
`esxcli storage vmfs unmap --volume-label=MCS_P5_VV_16785_DATA_02`

#### Find snapshots and how much space they're using
```powershell
Get-Cluster MyCluster | Get-VM | Get-Snapshot | Ft VM, Name, @{Label="NumSnapshots";Expression={($_ | Measure-Object).Count}}, @{Label="TotalSnapShotSizeGB";Expression={($_ | Measure-Object -Sum SizeGB).Sum}}
```

#### Check PSC replication 
For checking the replication status when updating vCenters in hybrid linked mode: 
```
/usr/lib/vmware-vmdir/bin/vdcrepadmin -f showfederationstatus -h localhost -u administrator
/usr/lib/vmware-vmdir/bin/vdcrepadmin -f showpartnerstatus -h localhost -u administrator
```
