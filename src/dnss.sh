#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/dnss.sh) --upstream=https://1.1.1.1/dns-query
###############################################################################

## GetArgValueEx <key> [defvalue]
## ./script --key=value
g_args=("$@")
function GetArgValueEx()
{
    local key="$1"

    for arg in "${g_args[@]}"
    do
        if [[ "$arg" == "$key="* || "$arg" == "--$key="* ]]
        then
            printf '%s\n' "${arg#*=}"
            return 0
        fi
    done

    if (( "$#" > 1 )); then
        printf '%s\n' "$2"
        return 0
    fi

    echo "Error: Unable to find arg: $key" >&2
    return 1
}

LISTENERS=$(ss -H -tuln 'sport = :53')
if [[ -n "$LISTENERS" ]]; then
    echo "Port 53 is already in use."
    exit 1
fi

UPSTREAM=$(GetArgValueEx "upstream" "https://1.1.1.1/dns-query")
apt-get update
apt-get install dnss -y

systemctl disable dnss.service --now
systemctl disable dnss.socket --now
if systemctl cat cloudflared-doh.service >/dev/null 2>&1; then
    systemctl disable cloudflared-doh.service --now
fi

cat <<EOF > /etc/systemd/system/dnss.service
[Unit]
Description=dnss daemon
Documentation=man:dnss

[Service]
Type=simple
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ProtectSystem=full
Restart=always
ExecStart=/usr/bin/dnss -enable_dns_to_https -https_upstream=$UPSTREAM -dns_listen_addr=127.0.0.1:53 -enable_cache

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart dnss.service
systemctl enable dnss.service

if [ -f /etc/dhcp/dhclient.conf ]; then
   sed -i "/^supersede domain-name-servers/d" /etc/dhcp/dhclient.conf
   echo 'supersede domain-name-servers 127.0.0.1;' >> /etc/dhcp/dhclient.conf
fi

## 等待 dnss 开始监听
for _ in {1..10}; do
    LISTENERS=$(ss -H -tuln 'sport = :53')
    [[ -n "$LISTENERS" ]] && break
    sleep 0.5
done
if [[ -z "$LISTENERS" ]]; then
    echo "dnss is not listening on port 53, resolv.conf unchanged." >&2
    exit 1
fi
cp /etc/resolv.conf /etc/resolv.conf.bak
echo 'nameserver 127.0.0.1' > /etc/resolv.conf
echo 'done!'
