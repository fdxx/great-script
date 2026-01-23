#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/q.sh)
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
VERSION=$(curl -fsSL "https://api.github.com/repos/natesales/q/releases/latest" | jq -r '.assets[] | select(.browser_download_url | test("linux_amd64.tar.gz")).browser_download_url') || exit 1
wget -O q.tar.gz "$VERSION" || exit 1

tar -xf q.tar.gz
chmod +x q
mv q /usr/bin
q --version

rm -rf q.tar.gz README.md LICENSE

