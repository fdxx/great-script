#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/realm.sh)
###############################################################################

mkdir -p "$HOME/apps/realm"
cd "$HOME/apps/realm"

wget -O "realm.tar.gz" "https://github.com/zhboner/realm/releases/latest/download/realm-x86_64-unknown-linux-gnu.tar.gz" || exit 1
tar -xf realm.tar.gz
chmod +x realm
rm -rf realm.tar.gz
./realm -v

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
