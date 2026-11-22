#!/bin/bash
# One liner to show crontabs for all users
for user in $(cut -f1 -d: /etc/passwd); do echo $user; crontab -u $user -l; done