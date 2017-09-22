#!/bin/bash

if [[ "$1" ]]; then
    commit="$1";
else
    commit="HEAD";
fi

if [ "$(git cat-file -t "$commit" 2> /dev/null)" != "commit" ]; then
    echo "Unknown commit: $commit";
    exit 1;
fi
hash=$(git rev-parse "$commit");
changed_files="$(git diff-tree --no-commit-id --name-only -r "$hash")"

clear;
git show --name-only "$hash";
read -rp "Press return to continue ...";

sel="-";
while true; do
    sel="$(echo "$changed_files" | \
        fzf --header "Select file to diff. Last was $sel" --reverse)";
    if [[ ! "$sel" ]]; then
        break;
    fi
    git difftool -y "$commit~" "$commit" -- "$sel"
done
