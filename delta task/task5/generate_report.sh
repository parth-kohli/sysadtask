#!/bin/bash

if ! id -nG "$USER" | grep -qw "g_admin"; then
        echo "Only admins can run this script"
        exit 1
fi

REPORT_DIR="/home/admin/$USER"
REPORT_FILE="$REPORT_DIR/blog_report_$(date +%Y-%m-%d).txt"

echo "Activity Report $(date)" > "$REPORT_FILE"

declare -A CATEGORY_MAP
for f in /home/authors/*/files/blogs.yaml; do
        [[ -f "$f" ]] || continue
        keys=$(yq e '.categories | keys' "$f" | sed 's/- //' | xargs)
        for id in $keys; do
                CATEGORY_MAP["$id"]="$(yq e ".categories.$id" "$f")"
        done
        break
done
declare -A TAG_PUBLISHED
declare -A TAG_DELETED
declare -A READ_COUNTS

for blogfile in /home/authors/*/files/blogs.yaml; do
        author=$(basename "$(dirname "$(dirname "$blogfile")")")
        blog_count=$(yq e '.blogs | length' "$blogfile")
        for ((i=0; i<blog_count; i++)); do
                status=$(yq e ".blogs[$i].publish_status" "$blogfile")
                file_name=$(yq e ".blogs[$i].file_name" "$blogfile")
                tag_ids=$(yq e ".blogs[$i].cat_order[]" "$blogfile")
                for tag_id in $tag_ids; do
                        tag="${CATEGORY_MAP[$tag_id]}"
                        if [[ "$status" == "true" ]]; then
                                ((TAG_PUBLISHED["$tag"]++))
                        else
                                ((TAG_DELETED["$tag"]++))
                        fi
                done
                readfile="/home/authors/$author/public/${file_name}.readcount"
                if [[ -f "$readfile" ]]; then
                        count=$(< "$readfile")
                        blog_key="$author:$file_name"
                        READ_COUNTS["$blog_key"]=$count
                fi
        done
done
echo -e "\nArticles:" >> "$REPORT_FILE"
all_tags=("${!CATEGORY_MAP[@]}")
for tag_name in "${CATEGORY_MAP[@]}"; do
        pub=${TAG_PUBLISHED[$tag_name]:-0}
        del=${TAG_DELETED[$tag_name]:-0}
        echo "$tag_name: Published = $pub, Deleted = $del" >> "$REPORT_FILE"
done


echo -e "\n Most-Read Articles:" >> "$REPORT_FILE"
for key in "${!READ_COUNTS[@]}"; do
        echo "${READ_COUNTS[$key]} $key"
done | sort -rn | head -n 3 | while read count blogkey; do
        author=${blogkey%%:*}
        file=${blogkey#*:}
        echo "$file by $author — $count reads" >> "$REPORT_FILE"
done

