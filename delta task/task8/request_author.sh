#!/bin/bash
username="${SUDO_USER:-USER}"
file="/home/admin/requests.yaml"
if sudo grep -qw "$username" "$file"; then
 	echo "You have already requested"
  	exit 1
fi
echo "- $username" | sudo tee -a "$file" > /dev/null
echo "Request sent"
