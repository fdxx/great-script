#!/bin/bash

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
        if [[ "$arg" == "--$key="* ]]
        then
            echo "${arg#*=}"
            return 0
        fi
    done

    if (( "$#" > 1 )); then
        echo "$2"
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
            apt-get update && APT_UPDATED=1 || return 1
        fi
        apt-get install "$packname" -y || return 1
    fi

    return 0
}

VERSION=$(GetArgValueEx "version" "")
RESETCMD=$(GetArgValueEx "resetcmd" "")

if [ -z "$VERSION" ]; then
    CheckInstCmd "jq" || exit 1
    VERSION=$(curl -fsSL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r '.name') || exit 1
fi

mkdir -p "$HOME/apps/sing-box/data"
cd "$HOME/apps/sing-box"

rm -rf tempdown && mkdir tempdown
wget -O tempdown/sing-box.tar.gz "https://github.com/SagerNet/sing-box/releases/download/v$VERSION/sing-box-$VERSION-linux-amd64.tar.gz" || exit 1
tar -xf tempdown/sing-box.tar.gz -C tempdown
cp "tempdown/sing-box-$VERSION-linux-amd64/sing-box" .
chmod +x sing-box
./sing-box version
rm -rf tempdown

if [ -f "data/box.log" ]; then
    cp data/box.log data/box.log.bak
    echo "" > data/box.log
fi

[ -n "$RESETCMD" ] && $RESETCMD restart sing-box
