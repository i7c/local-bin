#!/bin/bash
#
# This is a simple backup script using borg. It's supposed to serve as a
# starting point and to be adjusted to your system.
#
# Important steps:
#  - define a host "backup" in root's .ssh/config
#  - You can override variables from main() as well as the pre_backup() and post_backup() functions in
#    $XDG_CONFIG_HOME/backup-sh-conf.sh or /etc/backup-sh-conf.sh
#  - As root run `borg init -v --encryption=keyfile backup:borg-$(hostname)`
#  - If you want, increase the max_segment_size in
#    ssh://backup/borg-$HOSTNAME/config from the default 5MiB
#
# Copyright ©2014-2017 Florian Pritz <bluewind@xinu.at>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# See gpl-3.0.txt for full license text.

set -e

main() {
    if [[ $UID != 0 ]]; then
        exec sudo "$0" "$@"
    fi

    TMPDIR="$(mktemp -d "/tmp/${0##*/}.XXXXXX")"
    trap "rm -rf '${TMPDIR}'" EXIT TERM

    # The backup repository used by borg
    borg_repo="backup:borg-$HOSTNAME"

    # These mountpoints will be excluded. Mountpoints not listed in either this
    # or the includeMountpoints variable below will throw an error
    excludeMountpoints=(
        /tmp
        /sys
        /dev
        /proc
        /run
        /media
        /mnt/pool
    )

    # These mountpoints will be included
    includeMountpoints=(
        /
        /boot
        /home
    )

    # List of patterns that should be excluded. This supports shell globbing as
    # well as regex pattern. Refer to man borg for details.
	IFS='' read -r -d '' excludeList <<-EOF || true
		sh:/home/*/.cache/*
		sh:/root/.cache/*
		sh:/var/cache/pacman/pkg/*
	EOF

    for configfile in "${XDG_CONFIG_HOME:-$HOME/.config}/backup-sh-conf.sh" /etc/backup-sh-conf.sh; do
        if [[ -e "$configfile" ]]; then
            source "$configfile"
        fi
    done

    exclude_mountpoints
    echo "$excludeList" > "$TMPDIR/exclude-list-borg"

    run_if_exists pre_backup
    backup_borg / "$borg_repo"
    run_if_exists post_backup
}

# This is called before creating the backup
pre_backup() {
    # save some data that's useful for restores
    local backupDataDir=/root/backup-data/
    mkdir -p "$backupDataDir"
    fdisk -l > "$backupDataDir/fdisk"
    vgdisplay > "$backupDataDir/vgdisplay"
    pvdisplay > "$backupDataDir/pvdisplay"
    lvdisplay > "$backupDataDir/lvdisplay"
    df -a > "$backupDataDir/df"
    findmnt -l > "$backupDataDir/findmnt"

    # If you wish to use snapshots, create them here

    return
}

# This is called after backup creation
post_backup() {
    # If you need to perform any cleanup do so here

    return
}

backup_borg() {
    local src=$1
    local dst=$2
    local -a options=(
        --verbose
        --numeric-owner
        --compression lz4
        --exclude-from "$TMPDIR/exclude-list-borg"
        )

    if tty -s; then
        options+=(--progress --stats)
    fi

    borg create "${options[@]}" "$dst::backup-$(date "+%Y%m%d-%H%M%S")" "$src"
    borg prune --keep-within 7d --keep-daily 7 --keep-weekly 12 --keep-monthly 12 --keep-yearly 3 -v "$dst"
}

### support functions below ###

run_if_exists() {
    if declare -F $1 &> /dev/null; then
        $1 "${@:2}"
    fi
}

##
#  usage : in_array( $needle, $haystack )
# return : 0 - found
#          1 - not found
##
in_array() {
    local needle=$1; shift
    local item
    for item in "$@"; do
        [[ $item = "$needle" ]] && return 0 # Found
    done
    return 1 # Not Found
}

# same as in_array except 0 is returned if any item in haystack starts with needle
in_array_startswith() {
    local needle=$1; shift
    local item
    for item in "$@"; do
        [[ "$needle" == "$item"* ]] && return 0 # Found
    done
    return 1 # Not Found
}

exclude_mountpoints() {
    local error=0

    for fs in "${excludeMountpoints[@]}"; do
        excludeList+="sh:$fs/*"$'\n'
    done

    while read line; do
        local mountpoint=$(echo "$line" | cut -d\  -f2 | sed 's#\040# #g;')

        if ! in_array "$mountpoint" "${includeMountpoints[@]}"; then
            if ! in_array_startswith "$mountpoint/" "${excludeMountpoints[@]/%//}"; then
                error=1
                echo "Warning: mountpoint not excluded or included: $mountpoint" >&2
            fi
        fi
    done </etc/mtab

    if ((error)); then
        exit 1
    fi
}

main "$@"

