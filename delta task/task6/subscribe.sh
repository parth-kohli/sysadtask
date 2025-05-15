#!/bin/bash
if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <author1> [author2 ...]"
        exit 1
fi
user="$USER"
subscribed_authors=("$@")
user_dir="/home/users/$user"
target_dir="$user_dir/subscribed"
mkdir -p "$target_dir"
for author in "${subscribed_authors[@]}"; do
        sub="/home/authors/$author/subscribed"
        link="$target_dir/$author"
        if [[ -d "$sub" ]]; then
                if [[ ! -L "$link" ]]; then
                        ln -s "$sub" "$link"
                        echo "Subscribed to $author"
                else
                        echo "Already subscribed to $author"
                fi
        else
                echo "dir not found: $author_pub"
        fi
done
