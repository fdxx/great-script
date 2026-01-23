#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/ipaddr-test.sh) iface
###############################################################################

## GetIP <IFACE>
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
        ip $FAMILY addr show "$IFACE" | awk '/inet / {print $2}'
        return 0
    fi

    ip $FAMILY addr show "$IFACE" scope global | awk '/inet6 / {print $2}'
}

## GetIP <-4|-6> <IFACE>
function GetGateway()
{
    local FAMILY="$1"
    local IFACE="$2"
    local RESULT=$(ip $FAMILY route show default dev "$IFACE" | awk -F"via " '{print $2}' | awk '{print $1}')

    if [[ -z "$RESULT" ]]; then
        echo ""
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

    local IPV6_GW_MAC=$(ip -6 neigh show dev $IFACE | grep "${RESULT} " | awk -F"lladdr " '{print $2}' | awk '{print $1}')
    RESULT=$(ip -6 neigh show dev $IFACE | grep "${IPV6_GW_MAC} " | grep "fe80" | awk '{print $1}')
    echo "$RESULT"
}


IFACE=$1
MAC=$(GetMAC "$IFACE")
IPV4=$(GetIP -4 "$IFACE")
IPV4_GW=$(GetGateway -4 "$IFACE")
IPV6=$(GetIP -6 "$IFACE")
IPV6_GW=$(GetGateway -6 "$IFACE")

echo "--- ${IFACE} ---"
echo "MAC: $MAC"
echo "IPV4: $IPV4"
echo "IPV4_GW: $IPV4_GW"
echo "IPV6: $IPV6"
echo "IPV6_GW: $IPV6_GW"

