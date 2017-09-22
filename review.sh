#!/bin/bash

if [[ "$1" == "_" ]]; then
    shift;
    revlist="$(git log --color --graph --pretty="%H %s (%D)" "$@" -1024 | \
        fzf --reverse -m --ansi | \
        sed -r 's,^[| *]*([a-z0-9]* .*)$,\1,' | grep -P '\S')"
elif [[ "$1" ]]; then
    revlist="$(git log --reverse --format='%H - %s' "$@")";
else
    revlist="$(git log --reverse --format='%H - %s' "origin/master..HEAD")";
fi
# Obtain revlist to consider at all

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
