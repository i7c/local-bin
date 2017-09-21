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

revlist="$(git rev-list --reverse "$spec")"
for rev in $revlist; do
    clear;
    git show -s "$rev";
    echo "--------------------------------------------------------------------------------"
    git difftool "$rev~" "$rev"
done

