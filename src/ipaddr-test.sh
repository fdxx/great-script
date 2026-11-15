#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/ipaddr-test.sh) iface
###############################################################################

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



IFACE=${1:?Usage: ipaddr-test.sh iface}
MAC=$(GetMAC "$IFACE")
IPV4=$(GetIP -4 "$IFACE")
IPV4_GW=$(GetGateway -4 "$IFACE" || true)
IPV6=$(GetIP -6 "$IFACE")
IPV6_GW=$(GetGateway -6 "$IFACE" || true)

echo "--- ${IFACE} ---"
echo "MAC: $MAC"
echo "IPV4: $IPV4"
echo "IPV4_GW: $IPV4_GW"
echo "IPV6: $IPV6"
echo "IPV6_GW: $IPV6_GW"
echo 'done!'

