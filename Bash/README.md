# Bash handy tools and one liners

Useful things I've saved for Linux admin and troubleshooting. 

#### NCDU Disk space tool
```bash
wget https://dev.yorhel.nl/download/ncdu-linux-x86_64-1.15.1.tar.gz
tar -zxvf ncdu-linux-x86_64-1.15.1.tar.gz
./ncdu /
```

Alternatives using standard commands:
`find /path/to/search/ -type f -printf '%s %p\n'| sort -nr | head -10`

`find /var/lib -type f | sort -nr |  head -20 | while read line ; do du -h $line ; done`

#### Obfuscated PHP scanner

`wget https://github.com/evoforge/evomalware/archive/master.zip`

#### Find and remove a string

`find . -type f -name '*.php' -exec sed -i 's/[startstring].*[endstring]//g' {} \;`

#### View crontabs for all users

`for user in $(cut -f1 -d: /etc/passwd); do echo $user; crontab -u $user -l; done`
