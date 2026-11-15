#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/sing-box-update.sh) --version=1.12.17 --resetcmd=pm2
###############################################################################

## GetArgValueEx <key> [defvalue]
## ./script --key=value
g_args=("$@")
function GetArgValueEx()
{
    local key="$1"

    for arg in "${g_args[@]}"
    do
        if [[ "$arg" == "$key="* || "$arg" == "--$key="* ]]
        then
            printf '%s\n' "${arg#*=}"
            return 0
        fi
    done

    if (( "$#" > 1 )); then
        printf '%s\n' "$2"
        return 0
    fi

    echo "Error: Unable to find arg: $key" >&2
    return 1
}

## CheckInstCmd <cmd> [packname]
function CheckInstCmd()
{
    if (( "$#" < 1 )); then
        return 1
    fi

    : "${APT_UPDATED:=0}"

    local cmd="$1"
    local packname="${2:-$1}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        if (( APT_UPDATED == 0 )); then
            apt-get update
            APT_UPDATED=1
        fi
        apt-get install "$packname" -y
    fi

    return 0
}

VERSION=$(GetArgValueEx "version" "")
RESETCMD=$(GetArgValueEx "resetcmd" "")

if [ -z "$VERSION" ]; then
    CheckInstCmd "jq"
    VERSION=$(curl -fsSL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -er '.tag_name')
fi
VERSION=${VERSION#v}

mkdir -p "$HOME/apps/sing-box/data"
cd "$HOME/apps/sing-box"

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/sing-box.tar.gz" "https://github.com/SagerNet/sing-box/releases/download/v$VERSION/sing-box-$VERSION-linux-amd64.tar.gz"
tar -xf "$WORK_DIR/sing-box.tar.gz" -C "$WORK_DIR"
NEW_BINARY="$WORK_DIR/sing-box-$VERSION-linux-amd64/sing-box"
"$NEW_BINARY" version
if [ -f sing-box ]; then
    cp sing-box sing-box.bak
fi
## install 先删后建，运行中的旧进程不受影响，也不会 Text file busy
install -m755 "$NEW_BINARY" sing-box

if [ -n "$RESETCMD" ]; then
    # shellcheck disable=SC2086
    $RESETCMD stop sing-box
fi

if [ -f "data/box.log" ]; then
    cp data/box.log data/box.log.bak
    echo "" > data/box.log
fi

if [ -n "$RESETCMD" ]; then
    # shellcheck disable=SC2086
    $RESETCMD start sing-box
fi

echo 'done!'
