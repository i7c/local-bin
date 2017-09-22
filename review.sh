#!/bin/bash

if [[ "$2" ]]; then
    spec="$1..$2";
else
    if [[ "$1" ]]; then
        spec="$1";
    else
        spec="origin/master..HEAD";
    fi
fi

# Obtain revlist to consider at all
revlist="$(git log --reverse --format='%H - %s' "$spec")";

# Prompt for commit and inspect it in a loop until the user wants to exit
commit="-";
while true; do
    commit=$(echo "$revlist" | \
        fzf --reverse --header "Select commit to inspect. Last was $commit" | \
        awk '{print $1}');
    if [[ ! "$commit" ]]; then
        break;
    fi
    clear;
    inspect_commit.sh "$commit";
done;
exit 0;
