set -e 
MOD=$(whoami)
MOD_HOME="/home/mods/$MOD"
BLACKLIST="$MOD_HOME/blacklist.txt"
USERS="/users2.yaml"
if ! id -nG "$USER" | grep -qw "g_mod"; then
  echo "Only mods can run this script"
  exit 1
fi
[[ ! -f "$BLACKLIST" ]] && echo "Blacklist.txt not found" && exit 1
regex=$(tr '\n' '|' < "$BLACKLIST" | sed 's/|$//')
regex="(${regex})"
mapfile -t blacklist < "$BLACKLIST"
shopt -s nocasematch
mapfile -t AUTHORS < <(yq e ".mods[] | select(.username == \"$MOD\") | .authors[]" "$USERS")
for author in "${AUTHORS[@]}"; do
	auth_home="/home/authors/$author"
	pub_dir="$auth_home/public"
	yaml="$auth_home/files/blogs.yaml"
	[[ ! -f "$yaml" ]] && echo "Blacklist.txt not found" && exit 
	ls "$pub_dir"
	for file in "$pub_dir"/*.txt; do
		[[ -f "$file" ]] || continue
		temp=$(mktemp)
		match_count=0
		while IFS= read -r line; do
			newline="$line"
			newline="${newline,,}"
			for word in $newline; do
				for bad in "${blacklist[@]}"; do
					if [[ $word == $bad ]]; then
						stars=$(printf '%*s' "${#word}" '' | tr ' ' '*')
						newline="${newline//$word/$stars}"
						match_count=$((match_count + 1))
						echo "Found blacklisted word \"$word\" in $file at line $((LINENO + 1))"
					fi
				done
			done
		echo "$newline" >> "$temp"
	done < "$file"
	if [[ "$match_count" -gt 0 ]]; then 
		mv "$temp" "$file"
	else 
		rm "$temp"
	fi 
	if [[ "$match_count" -gt 5 ]]; then
		echo "Blog $(basename "$file") is archived due to excessive blacklisted words."
		rm -f "$file"
		if [[ -f "$yaml" ]]; then
			filename=$(basename "$file")
			comment="found $match_count blacklisted words"
			yq -i ".blogs[] |= (select(.file_name == \"$blogname\") | .publish_status = false)" "$blogfile"
			yq -i "(.blogs[] | select(.file_name == \"$filename\")).mod_comments = \"$comment\"" "$yaml"
		fi 
	fi
	done 
done 
exit -1
