#!/bin/bash
set -e
YAML_FILE="users2.yaml"
unset GROUPS
declare -A GROUPS=(
[users]=g_user
[authors]=g_author
[mods]=g_mod
[admins]=g_admin
)
unset BASE_DIRS
declare -A BASE_DIRS=(
[users]="/home/users"
[authors]="/home/authors"
[mods]="/home/mods"
[admins]="/home/admin"
)

create_group(){
	local group="$1"
	getent group "$group">/dev/null || groupadd "$group" 
}
create_user(){
	echo "$username"
	local username="$1"
	local group="$2"
	local role="$3"
	local home="${BASE_DIRS[$role]}/$username"
	if ! id "$username" &>/dev/null; then
		useradd -m -d "$home" -g "$group" "$username"
	else 
		usermod -d "$home" -g "$group" "$username"
	fi
	mkdir -p "$home"
	chown "$username:$group" "$home"
	chmod 755 "$home"
	
	if [[ "$role" == "authors" ]];then
		mkdir -p "$home/blogs" "$home/public"
		chown "$username:$group" "$home/blogs" "$home/public"
		chmod 700 "$home/blogs"
		chmod 755 "$home/public"
	fi
}
give_admin_access() {
	local admin="$1"
	for path in /home/*/*; do
		[[ -d "$path" ]] && setfacl -m u:$admin:rwx "$path"
	done
}
create_all_blogs_symlinks() { 
	local user="$1"
	echo $user
	local blog_dir="/home/users/$user/all_blogs"
	mkdir -p "$blog_dir"
	local sub_dir="/home/users/$user/subscribed"
	mkdir -p "$sub_dir"
	
	chown "$user:${GROUPS[users]}" "$blog_dir"
	chown "$user:${GROUPS[users]}" "$sub_dir"
	find "$blog_dir" -type l -delete
	for author in $(yq e '.authors[].username' "$YAML_FILE"); do
		local target="/home/authors/$author/public"
		[[ -d "$target" ]] && ln -s "$target" "$blog_dir/$author"
	done
	find "$sub_dir" -type l -delete
	chmod -R 555 "$blog_dir"
	chmod -R 755 "$sub_dir"
	chmod +x "$sub_dir"
	notif_file="/home/users/$user/notifications.log"
 	if [[ ! -f "$notif_file" ]]; then
    		echo "new_notifications" > "$notif_file"
    		chmod 777 "$notif_file"	
  	fi
}
assign_moderator_access(){
	local mod_username="$1"
	local assigned_authors=($(yq e ".mods[] | select(.username == "$mod_username") | .authors[]" "$YAML_FILE"))
	for author in "${assigned_authors[@]}"; do
		local pub_dir="/home/authors/$author/public"
		[[ -d "$pub_dir" ]] &&  setfacl -m u:$mod_username:--x /home && setfacl -m u:$mod_username:--x /home/authors && setfacl -m u:$mod_username:--x /home/authors/$author && setfacl -m u:$mod_username:rwX "$pub_dir" && setfacl -m u:$mod_username:rwX "$home/authors/$author"
	done
}
for group in "${GROUPS[@]}";do
	create_group "$group"
done
for dir in "${BASE_DIRS[@]}"; do
	mkdir -p "$dir"
done
for role in users authors admins; do
	role_key="$role"
	[[ "$role" == "admins" ]] && role_key="admins"
	[[ "$role" == "authors" ]] && role_key="authors"
	[[ "$role" == "users" ]] && role_key="users"
	user_count=$(yq e ".${role_key} | length" "$YAML_FILE")
	for ((i=0;i<user_count; i++)); do
		
		username=$(yq e ".${role_key}[$i].username" "$YAML_FILE")
		create_user "$username" "${GROUPS[$role_key]}" "$role_key"
		[[ "$role_key" == "users" ]] && create_all_blogs_symlinks "$username"
		[[ "$role_key" == "admins" ]] && give_admin_access "$username"
	done
done
mod_count=$(yq e ".mods | length" "$YAML_FILE")
for ((i=0;i<mod_count; i++)); do
		mod_username=$(yq e ".mods[$i].username" "$YAML_FILE")
		create_user "$mod_username" "${GROUPS[mods]}" "mods"
		assign_moderator_access "$mod_username"
	done
