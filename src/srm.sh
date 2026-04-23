#!/bin/bash

TRASH_DIR="$HOME/.trash"
mkdir -p "$TRASH_DIR"

force_delete=false
clean_trash=false
all_users=false

usage() {
    echo "Usage: $(basename "$0") [-f] [-c [-a]] file..."
    echo "  -f    Force delete (skip trash)"
    echo "  -c    Clean trash"
    echo "  -a    With -c: clean all users trash"
    exit 1
}

while getopts "fca" opt; do
    case $opt in
        f) force_delete=true ;;
        c) clean_trash=true ;;
        a) all_users=true ;;
        *) usage ;;
    esac
done

shift $((OPTIND - 1))

# Handle Trash Cleaning
if [ "$clean_trash" = true ]; then
    if [ "$all_users" = true ]; then
        echo "Cleaning all users trash..."

        for trash in /home/*/.trash /root/.trash; do
            [ -d "$trash" ] || continue
            echo "Cleaning $trash"
            find "$trash" -mindepth 1 -delete
        done

    else
        echo "Cleaning current user trash: $TRASH_DIR"
        find "$TRASH_DIR" -mindepth 1 -delete
    fi

    exit 0
fi

if [ $# -eq 0 ]; then
    usage
fi

is_protected() {
    local abs_target
    abs_target=$(readlink -f "$1") || return 0

    local protected_paths=(
        "/"
        "$HOME"
        "$TRASH_DIR"
        "/etc"
        "/usr"
        "/boot"
    )

    for p in "${protected_paths[@]}"; do
        local abs_p=$(readlink -f "$p")
        if [[ "$abs_target" == "$abs_p" ]]; then
            return 0
        fi
    done

    return 1
}

# Check if target and trash are on different filesystems
is_cross_filesystem() {
    local target="$1"
    local target_dev trash_dev
    
    # Get device ID of target (works for both files and directories)
    target_dev=$(stat -c '%d' "$target" 2>/dev/null) || return 1
    
    # Get device ID of trash directory
    trash_dev=$(stat -c '%d' "$TRASH_DIR" 2>/dev/null) || return 1
    
    # Compare device IDs
    if [ "$target_dev" != "$trash_dev" ]; then
        return 0  # Different filesystems
    else
        return 1  # Same filesystem
    fi
}

for target in "$@"; do
    if [ ! -e "$target" ]; then
        echo "srm: '$target' does not exist."
        continue
    fi

    if is_protected "$target"; then
        echo "srm: refusing to remove protected path '$target'"
        continue
    fi

    if [ "$force_delete" = true ]; then
        rm -rf -- "$target"
        echo "Permanently deleted '$target'"
        continue
    fi

    # Check for cross-filesystem operation
    if is_cross_filesystem "$target"; then
        echo "srm: refusing to move '$target'"
        echo "      crosses filesystem Use 'rm -rf' or '-f' flag for permanent deletion."
        continue
    fi

    filename=$(basename -- "$target")
    dest="$TRASH_DIR/$filename"

    if [ -e "$dest" ]; then
        suffix="$(date +"%Y%m%d%H%M%S_%N")"
        dest="${dest}_${suffix}"
    fi

    if mv -- "$target" "$dest"; then
        echo "Moved to trash: '$target'"
    else
        echo "srm: failed to move '$target'. Check permissions." >&2
    fi
done
