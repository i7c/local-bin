#!/bin/bash

seen_file=$(mktemp)

seen() {
    grep -q "$@" "$seen_file";
}

saw() {
    if ! seen "$@"; then
        echo "$@" >> $seen_file;
    fi
}

list_revs() {
    local prefix;
    while read -r r; do
        if seen "$r"; then
            git log --pretty='%H [X] - %s (%D)' "$r" -1;
        else
            git log --pretty='%H [ ] - %s (%D)' "$r" -1;
        fi
    done <<< $revlist;
}

if [[ "$1" == "_" ]]; then
    shift;
    revlist="$(git log --color --graph --pretty="%H %s (%D)" "$@" -1024 | \
        fzf --reverse -m --ansi | \
        sed -r 's,^[| *]*([a-z0-9]*).*$,\1,' | grep -P '\S')"
elif [[ "$1" ]]; then
    revlist="$(git log --reverse --format='%H' "$@")";
else
    revlist="$(git log --reverse --format='%H' "origin/master..HEAD")";
fi

# Prompt for commit and inspect it in a loop until the user wants to exit
commit="-";
while true; do
    commit=$(list_revs | \
        fzf --reverse --header "Select commit to inspect. Last was $commit" | \
        awk '{print $1}');
    if [[ ! "$commit" ]]; then
        break;
    fi
    saw "$commit";
    clear;
    inspect_commit.sh "$commit";
done;

rm "$seen_file";
exit 0;
