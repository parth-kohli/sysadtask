#!/bin/bash
AUTHOR=$(whoami)
BASE="/home/authors/$AUTHOR"
BLOG_DIR="$BASE/blogs"
PUBLIC_DIR="$BASE/public"
SUB_DIR="$BASE/subscribed"
YAML="$BASE/files/blogs.yaml"
[[ -f "$YAML" ]] || echo "no exist"
if ! id -nG "$USER" | grep -qw "g_author"; then
  echo "Only authors can run this script"
  exit 1
fi
categories() {
	#1
	mapfile -t CATEGORY_IDS < <(yq e '.categories | keys | .[]' "$YAML")
	declare -gA CATEGORY_MAP

	for id in "${CATEGORY_IDS[@]}"; do
		name=$(yq e ".categories.${id}" "$YAML")
		CATEGORY_MAP[$id]="$name"
	done
	for i in "${!CATEGORY_MAP[@]}"; do
		echo "$i) ${CATEGORY_MAP[$i]}" 
	done;
}
select_cat(){ 
	read -rp "Enter numbers in order: " input
	echo "$input"
}
update_yaml(){
	local file="$1"
	local status="$2"
	local cat_array="$3"
	echo ${cat_array[@]}
	yq -i "del(.blogs[] | select (.file_name == \"$file\"))" "$YAML"
	yq eval  ".blogs += [{\"file_name\": \"$file\", \"publish_status\": $status, \"cat_order\": $cat_array}]" -i "$YAML" 
}
broadcast(){
	file=$1
	for user in /home/users/*; do
 		username=$(basename "$user")
  		sub_dir="$user/subscribed"
  		if [[ -L "$sub_dir/$USER" ]]; then
   			 echo "From $USER: Published $file" | nc -q 0 localhost 5555
 		 fi
	done
}
publish(){
	local file="$1"
	[[ ! -f "$BLOG_DIR/$file" ]] && dir "$BLOG_DIR" &&  echo "file not found" && exit 1
	categories
	selected=$(select_cat)
	IFS=',' read -ra cat_ids <<< "$selected"
	cat_array="[${cat_ids[*]}]"
	cat_array="${cat_array// /,}"
	read -rp "Is it subscribed (y/n): " input
	sub="$input"
	if [[ $sub == "y" ]]; then
		cp "$BLOG_DIR/$file" "$SUB_DIR/$file"
		chmod 644 "$SUB_DIR/$file"
	elif [[ $sub == "n" ]]; then
		cp "$BLOG_DIR/$file" "$PUBLIC_DIR/$file"
		chmod 644 "$PUBLIC_DIR/$file"
	fi
	echo 0 > "$PUBLIC_DIR/$file.readcount"
	chmod 777 "$PUBLIC_DIR/$file.readcount"

	dir "$BASE/files"
	update_yaml "$file" true "$cat_array"
	broadcast $file
}
archive(){
	local file="$1"
	[[ -f "$PUBLIC_DIR/$file" ]] && (rm -f "$PUBLIC_DIR/$file" || "$SUB_DIR/$file")  && rm -f "$PUBLIC_DIR/$file.readcount"
	yq -i ".blogs[] |= (select(.file_name == \"$file\") | .publish_status = false)" "$YAML"
}
delete(){
	local file="$1"
  	rm -f "$BLOG_DIR/$file" "$PUBLIC_DIR/$file" "$SUB_DIR/$file"
	rm -f "$PUBLIC_DIR/$file.readcount"
 	 yq -i "del(.blogs[] | select(.file_name == \"$file\"))" "$YAML"
}
edit(){
	local file="$1"
	categories
	selected=$(select_cat)
	IFS=',' read -ra cat_ids <<< "$selected"
	cat_array="[${cat_ids[*]}]"
	cat_array="${cat_array// /,}"
	yq -i ".blogs[] |= select(.file_name == \"$file\") .cat_order = $cat_array" "$YAML"
}
main() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: $0 {-p|-a|-d|-e} <filename>"
    exit 1
  fi

  action="$1"
  file="$2"

  case "$action" in
    -p) publish "$file" ;;
    -a) archive "$file" ;;
    -d) delete "$file" ;;
    -e) edit "$file" ;;
    *) echo "Unknown command: $action" && exit 1 ;;
  esac
}

main "$@"
