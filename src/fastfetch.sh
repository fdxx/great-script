#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/fastfetch.sh)
###############################################################################

function CheckPkgOrExit()
{
    local pkg="$1" status
    status=$(dpkg-query -W -f='${db:Status-Status}' "$pkg" 2>/dev/null || true)
    if [[ "$status" == "installed" ]]; then
        echo "$pkg has already installed by Debian package!"
        exit 0
    fi
}

CheckPkgOrExit fastfetch

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/fastfetch.tar.gz" "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz"
tar -xf "$WORK_DIR/fastfetch.tar.gz" -C "$WORK_DIR"
install -Dm755 "$WORK_DIR/fastfetch-linux-amd64/usr/bin/fastfetch" /opt/fastfetch/fastfetch
ln -sfnT /opt/fastfetch/fastfetch /usr/local/bin/fastfetch
rm -fv /usr/bin/fastfetch
/opt/fastfetch/fastfetch
echo 'done!'
