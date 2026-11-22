# Useful commands for Cisco UCS blade systems 

#### Show the running processes
```
connect local-mgmt a
(local-mgmt)# show pmon state
```

#### Show CPU and memory use
```
connect nxos a 
(nx-os)# show system resources
```

#### UCS regenerate default keyring
```
scope security
scope keyring default
set regenerate yes
commit-buffer
```


#### Change service template initial power state

SSH to FI and run:
```
scope org /MyOrg
show service-profile
enter service-profile MyProfile initial-template
show 
power down
commit-buffer
exit
```
