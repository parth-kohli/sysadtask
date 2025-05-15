#!/bin/bash
NOTIF_FILE="$HOME/notifications.log"
if [ ! -f "$NOTIF_FILE" ]; then
        exit 0
fi
NEW_NOTIFS=$(awk '/^new_notifications/{flag=1;next}/^$/{next}flag' "$NOTIF_FILE")
if [ -n "$NEW_NOTIFS" ]; then
        COUNT=$(echo "$NEW_NOTIFS" | wc -l)
        echo -e "\n📬 You have $COUNT unread notifications:"
        echo "$NEW_NOTIFS"
        grep -v '^new_notifications$' "$NOTIF_FILE" > "$NOTIF_FILE.tmp"
        echo "new_notifications" >> "$NOTIF_FILE.tmp"
        mv "$NOTIF_FILE.tmp" "$NOTIF_FILE"
fi

