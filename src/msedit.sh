#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/msedit.sh)
###############################################################################

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

CheckInstCmd "jq" || exit 1
VERSION=$(curl -fsSL "https://api.github.com/repos/microsoft/edit/releases/latest" | jq -r '.assets[] | select(.browser_download_url | test("-x86_64-linux-gnu.tar.zst")).browser_download_url') || exit 1

wget -O edit.tar.zst "$VERSION" || exit 1
tar -I zstd -xf edit.tar.zst
chmod +x edit
mv edit /usr/bin/msedit
msedit -v 

rm -rf edit.tar.zst
