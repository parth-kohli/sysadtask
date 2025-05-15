#!/bin/bash
author="$1"
blog="$2"
blog_path="/home/authors/$author/public/$blog"
readcount_path="${blog_path}.readcount"

if [[ -z "$author" || -z "$blog" ]]; then
         echo "Usage: $0 <author_username> <blog_filename>"
         exit 1
fi

if [[ ! -f "$blog_path" ]]; then
         echo "Blog not found at $blog_path"
         exit 1
fi


if [[ ! -r "$blog_path" ]]; then
         echo "You don't have permission to read this blog directly"
         exit 1
fi

if [[ -f "$readcount_path" ]]; then
         count=$(< "$readcount_path")
         echo $((count + 1)) > "$readcount_path"
else
         echo 1 > "$readcount_path"
fi
cat "$blog_path"


