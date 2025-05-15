#!/bin/bash 
for USER_HOME in /home/users/*; do
        USERNAME=$(basename "$USER_HOME")
        NOTIF_FILE="$USER_HOME/notifications.log"
        echo $USERNAME
        [ -f "$NOTIF_FILE" ] || continue
        if who | grep -q "^$USERNAME\b"; then
                NEW_COUNT=$(awk '/^new_notifications/{flag=1;next}/^$/{next}flag' "$NOTIF_FILE" | wc -l)
                if [ "$NEW_COUNT" -gt 0 ]; then
                        for TTY in $(who | awk -v user="$USERNAME" '$1 == user {print $2}'); do
                                echo -e "\nYou have $NEW_COUNT new notifications Use 'cat ~/notifications.log' to view" | write "$USERNAME" "$TTY"
                        done
                fi
        fi
done

