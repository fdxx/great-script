#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nexttrace.sh)
###############################################################################

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/nexttrace" "https://github.com/nxtrace/NTrace-core/releases/latest/download/nexttrace_linux_amd64"
install -Dm755 "$WORK_DIR/nexttrace" /opt/nexttrace/nexttrace
ln -sfnT /opt/nexttrace/nexttrace /usr/local/bin/nexttrace
rm -fv /usr/bin/nexttrace
/opt/nexttrace/nexttrace --version
echo 'done!'
