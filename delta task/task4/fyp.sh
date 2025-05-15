#!/bin/bash
if ! id -nG "$USER" | grep -qw "g_admin"; then
        echo "Only admins can run script"
        exit 1
fi
USERPREF="userpref.yaml"
[[ ! -f "$USERPREF" ]] && echo "userpref.yaml not found" && exit 1
declare -A user_prefs
mapfile -t usernames < <(yq e '.users[].username' "$USERPREF")

for i in "${!usernames[@]}"; do
        u="${usernames[$i]}"
        p1=$(yq e ".users[$i].pref1" "$USERPREF")
        p2=$(yq e ".users[$i].pref2" "$USERPREF")
        p3=$(yq e ".users[$i].pref3" "$USERPREF")
        user_prefs["$u"]="$p1,$p2,$p3"
done
declare -A blog_tags                         
declare -A authors                
declare -A assigns                
blog_list=()
declare -A CAT_ID_TO_NAME
for blogfile in /home/authors/*/files/blogs.yaml; do
        [[ -f "$blogfile" ]] || continue
        ids=$(yq e '.categories | keys' "$blogfile" | sed 's/- //' | xargs)
        for id in $ids; do
                name=$(yq e ".categories.${id}" "$blogfile")
                CAT_ID_TO_NAME["$id"]="$name"
        done
        break
done
for blogfile in /home/authors/*/files/blogs.yaml; do
        author=$(basename "$(dirname "$(dirname "$blogfile")")")
        count=$(yq e '.blogs | length' "$blogfile")
        for ((i=0; i<count; i++)); do
                pub=$(yq e ".blogs[$i].publish_status" "$blogfile")
                [[ "$pub" != "true" ]] && continue
                fname=$(yq e ".blogs[$i].file_name" "$blogfile")
                raw_tags=$(yq e ".blogs[$i].cat_order[]" "$blogfile")
                tags=""
                while IFS= read -r tag_id; do
 	 tag_name="${CAT_ID_TO_NAME[$tag_id]}"
        	tags+="$tag_name,"
                done <<< "$raw_tags"
                tags="${tags%,}"  
                blog_id="$author:$fname"
                blog_list+=("$blog_id")
                blog_tags["$blog_id"]="$tags"
                authors["$blog_id"]="$author"
                assigns["$blog_id"]=0
        done
done
echo ${blog_tags[@]}
declare -A user_fyi
for u in "${usernames[@]}"; do
        IFS=',' read -ra prefs <<< "${user_prefs[$u]}"
        declare -A score_map
        
        for blog in "${blog_list[@]}"; do
                IFS=',' read -ra tags <<< "${blog_tags[$blog]}"
                score=0
	
                for ((p=0; p<3; p++)); do
                        for t in "${tags[@]}"; do
                                [[ "${prefs[$p]}" == "$t" ]] && ((score+=3-p))
                        done
                done
                [[ $score -ge 0 ]] && score_map["$blog"]=$score
        done
        echo "${score[@]}"
        top=$(for b in "${!score_map[@]}"; do
                echo "${score_map[$b]} ${assigns[$b]} $b"
        done | sort -k1,1nr -k2,2n | awk '{print $3}' | head -n 3)

        user_fyi["$u"]="$top"
        for b in $top; do
                ((assigns["$b"]++))
        done
done
for u in "${usernames[@]}"; do
        userdir="/home/users/$u"
        fyipath="$userdir/FYI.yaml"
        mkdir -p "$userdir"
        echo "blogs:" > "$fyipath"
        for b in ${user_fyi[$u]}; do
                author="${authors[$b]}"
                file="${b#*:}"
                echo "        - author: $author" >> "$fyipath"
                echo "                file: $file" >> "$fyipath"
        done
done
echo "FYI Yaml generated"
