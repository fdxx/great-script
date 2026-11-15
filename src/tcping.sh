#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/tcping.sh)
###############################################################################

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/tcping.tar.gz" "https://github.com/pouriyajamshidi/tcping/releases/latest/download/tcping-linux-amd64-static.tar.gz"
tar -xf "$WORK_DIR/tcping.tar.gz" -C "$WORK_DIR"
install -Dm755 "$WORK_DIR/tcping" /opt/tcping/tcping
ln -sfnT /opt/tcping/tcping /usr/local/bin/tcping
rm -fv /usr/bin/tcping
/opt/tcping/tcping -v
echo 'done!'
