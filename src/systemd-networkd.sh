#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/systemd-networkd.sh) --dhcp=0 --iface=eth0
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

## GetMAC <IFACE>
function GetMAC()
{
    ip link show "$1" | awk '/link\/ether/ {print $2}'
}

## GetIP <-4|-6> <IFACE>
function GetIP()
{
    local FAMILY="$1"
    local IFACE="$2"

    if [[ "$FAMILY" == "-4" ]]; then
        ip "$FAMILY" addr show "$IFACE" | awk '/inet / {print $2}'
    else
        ip "$FAMILY" addr show "$IFACE" scope global | awk '/inet6 / {print $2}'
    fi
}

## GetGateway <-4|-6> <IFACE>
function GetGateway()
{
    local FAMILY="$1"
    local IFACE="$2"
    local RESULT IPV6_GW_MAC
    RESULT=$(ip $FAMILY route show default dev "$IFACE" | awk -F"via " '{print $2}' | awk '{print $1}')

    if [[ -z "$RESULT" ]]; then
        return 1
    fi

    if [[ "$FAMILY" == "-4" ]]; then
        echo "$RESULT"
        return 0
    fi

    if echo "$RESULT" | grep -q "fe80"; then
        echo "$RESULT"
        return 0
    fi

    ## 如果v6网关不是链路本地，我们获取链路本地地址
    IPV6_GW_MAC=$(ip -6 neigh show dev $IFACE | grep "${RESULT} " | awk -F"lladdr " '{print $2}' | awk '{print $1}')
    RESULT=$(ip -6 neigh show dev $IFACE | grep "${IPV6_GW_MAC} " | grep "fe80" | awk '{print $1}')
    [ -n "$RESULT" ] && echo "$RESULT" || return 1
}


DHCP=$(GetArgValueEx "dhcp")
IFACE=$(GetArgValueEx "iface")

if ! ip link show "$IFACE" > /dev/null 2>&1; then
    echo "interface $IFACE does not exist."
    exit 1
fi 


MAC=$(GetMAC "$IFACE")
IPV4=$(GetIP -4 "$IFACE")
IPV4_GW=$(GetGateway -4 "$IFACE" || true)
IPV6=$(GetIP -6 "$IFACE")
IPV6_GW=$(GetGateway -6 "$IFACE" || true)

CONF=$(cat <<EOF
[Match]
MACAddress=$MAC
Type=ether

[Link]
RequiredForOnline=yes

[Network]
DHCP=ipv4
IPv6AcceptRA=yes

[DHCPv4]
UseDNS=false
UseRoutes=false
UseGateway=true

[IPv6AcceptRA]
UseDNS=false
EOF
)


## 每个地址一行 Address=，网关写入 [Route] 才能使 GatewayOnLink 生效
function StaticConf()
{
    local ADDR GW
    printf '[Match]\nMACAddress=%s\nType=ether\n\n' "$MAC"
    printf '[Link]\nRequiredForOnline=yes\n\n'
    printf '[Network]\nIPv6AcceptRA=false\n'
    for ADDR in $IPV4 $IPV6; do
        printf 'Address=%s\n' "$ADDR"
    done
    for GW in $IPV4_GW $IPV6_GW; do
        printf '\n[Route]\nGateway=%s\nGatewayOnLink=yes\n' "$GW"
    done
}

if [ "$DHCP" -eq 0 ]; then
    CONF=$(StaticConf)
fi


FILENAME="/etc/systemd/network/$IFACE.network"
mkdir -p /etc/systemd/network
echo "$CONF" > "$FILENAME"

if [ -f /etc/network/interfaces ]; then
    mv /etc/network/interfaces /etc/network/interfaces1.bak
fi
if systemctl cat networking.service >/dev/null 2>&1; then
    systemctl disable networking.service
fi
systemctl enable systemd-networkd.service

cat "$FILENAME"
echo "need: systemctl restart systemd-networkd.service"
echo 'done!'
