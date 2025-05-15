#!/bin/bash
requests_file="/home/admin/requests.yaml"
all_blogs_dir="/home/users/all_blogs"
if ! id -nG "$USER" | grep -qw "g_admin"; then
        echo "Only admins can run this script"
        exit 1
fi
[[ -f "$requests_file" ]] || { echo "No requests found."; exit 0; }
mapfile -t requests < <(yq e '.[]' "$requests_file")
if [[ ${#requests[@]} -eq 0 ]]; then
        echo "No new requests"
        exit 0
fi
echo "📨 Pending author requests:"
for i in "${!requests[@]}"; do
        echo "$((i + 1)). ${requests[$i]}"
done
read -p "Enter number to approve (or 0 to cancel): " choice
if [[ "$choice" -eq 0 ]]; then
        echo "Approval cancelled"
        exit 0
fi
username="${requests[$((choice - 1))]}"
old_home="/home/users/$username"
new_home="/home/authors/$username"
if [[ ! -d "$old_home" ]]; then
        echo " does not exist: $old_home"
        exit 1
fi
echo "Approving $username as author..."
sudo usermod -g g_author "$username"
sudo mv "$old_home" "$new_home"
sudo mkdir -p "$new_home/blogs" "$new_home/public"
sudo chown -R "$username":g_author "$new_home"
for allblogs in /home/users/*/all_blogs; do
	sudo ln -s "$new_home/public" "$allblogs/$username"
done
yq -i "del(.[] | select(. == \"$username\"))" "$requests_file"
echo "$username is added to author"
