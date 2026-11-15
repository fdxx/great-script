#!/bin/bash

set -euo pipefail

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
            apt-get update
            APT_UPDATED=1
        fi
        apt-get install "$packname" -y
    fi

    return 0
}

CheckInstCmd "jq"
CheckInstCmd "zstd"
VERSION=$(curl -fsSL "https://api.github.com/repos/microsoft/edit/releases/latest" | jq -er '.assets[] | select(.name | endswith("-x86_64-linux-gnu.tar.gz")) | .browser_download_url')

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/edit.tar.gz" "$VERSION"
tar -xf "$WORK_DIR/edit.tar.gz" -C "$WORK_DIR"
install -Dm755 "$WORK_DIR/edit" /opt/msedit/msedit
ln -sfnT /opt/msedit/msedit /usr/local/bin/msedit
rm -fv /usr/bin/msedit
/opt/msedit/msedit --version
echo 'done!'
