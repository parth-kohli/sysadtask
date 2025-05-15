#!/bin/bash
notif_file="/home/users/$USER/notifications.log"
mkdir -p "/home/users/$USER"
[[ -f "$notif_file" ]] || echo "new_notifications" > "$notif_file"
while true; do
	nc -l -p 5555 >> "$notif_file"
done
