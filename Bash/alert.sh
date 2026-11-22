#!/bin/bash

########
# Script name:  alert.sh
# Version:      1.1
# Dependencies: Bash shell, python, +x file permissions
# Description: vCenter script to attach to alarms. Passes the information from the alarm to a teams webhook.
# Documentation here:
# https://docs.vmware.com/en/VMware-vSphere/6.7/com.vmware.vsphere.monitoring.doc/GUID-AB74502C-5F01-478D-AF66-672AB5B8065C.html
# Create custom log file for debugging if required: /var/log/vcenter_alarms.log
# Change log
# v1.1 - 05/04/2021
#   * JSON special character stripping
########

# A python one-liner to strip out special chars that cause issues in JSON
# [1:-1] strips the encapsulating quotes because we add those in generating_post_data
json_escape()
{
    printf '%s' "$1" | python -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])'
}

# Environment variables (JSON escaped)
alarm_name=$(json_escape "$VMWARE_ALARM_NAME")
alarm_id=$(json_escape "$VMWARE_ALARM_ID")
alarm_target_name=$(json_escape "$VMWARE_ALARM_TARGET_NAME")
alarm_datacenter=$(json_escape "$VMWARE_ALARM_EVENT_DATACENTER")
alarm_username=$(json_escape "$VMWARE_ALARM_EVENT_USERNAME")
alarm_description=$(json_escape "$VMWARE_ALARM_EVENTDESCRIPTION")
alarm_value=$(json_escape "$VMWARE_ALARM_ALARMVALUE")

# Teams webhook
webhook="https://<Get this from a teams channel admin>"

generate_post_data()
{
cat <<EOF
{
        "@context": "http://schema.org/extensions",
        "@type": "MessageCard",
        "title": "$alarm_name - $alarm_target_name",
        "text": "vCenter: $alarm_datacenter
            \n\n Target: $alarm_target_name
            \n\n User: $alarm_username
            \n\n $alarm_description"
}
EOF
}

# Debugging, uncomment if needed:
#echo "$(generate_post_data)" >> /var/log/vcenter_alarms.log

# Trigger Web Hook
curl -k -X POST $webhook -H "Content-Type: application/json" --data "$(generate_post_data)" >> /var/log/vcenter_alarms.log
