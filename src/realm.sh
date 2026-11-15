#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/realm.sh)
###############################################################################

mkdir -p "$HOME/apps/realm"
cd "$HOME/apps/realm"

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/realm.tar.gz" "https://github.com/zhboner/realm/releases/latest/download/realm-x86_64-unknown-linux-gnu.tar.gz"
tar -xf "$WORK_DIR/realm.tar.gz" -C "$WORK_DIR"
install -m755 "$WORK_DIR/realm" realm
./realm -v

## 升级时保留已有配置
if [ ! -f config.json ]; then
    cat <<'EOF' > config.json
{
    "log": {
        "level": "warn",
        "output": "stdout"
    },
    "network": {
        "no_tcp": false,
        "use_udp": true,
        "tcp_keepalive": 0
    },
    "endpoints": [
        {
            "listen": "[::0]:1234",
            "remote": "10.0.0.1:5678"
        }
    ]
}
EOF
fi
echo 'done!'
