#!/bin/bash

set -euo pipefail

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
            apt-get update
            APT_UPDATED=1
        fi
        apt-get install "$packname" -y
    fi

    return 0
}

CheckInstCmd "jq"
VERSION=$(curl -fsSL "https://api.github.com/repos/natesales/q/releases/latest" | jq -er '.assets[] | select(.name | endswith("linux_amd64.tar.gz")) | .browser_download_url')
WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/q.tar.gz" "$VERSION"
tar -xf "$WORK_DIR/q.tar.gz" -C "$WORK_DIR"
install -Dm755 "$WORK_DIR/q" /opt/q/q
ln -sfnT /opt/q/q /usr/local/bin/q
rm -fv /usr/bin/q
/opt/q/q --version
echo 'done!'
