#!/bin/bash

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
        if [[ "$arg" == "--$key="* ]]
        then
            echo "${arg#*=}"
            return 0
        fi
    done

    if (( "$#" > 1 )); then
        echo "$2"
        return 0
    fi

    echo "Error: Unable to find arg: $key" >&2
    return 1
}

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

DHCP=$(GetArgValueEx "dhcp") || exit 1
IFACE=$(GetArgValueEx "iface") || exit 1

if ! ip link show "$IFACE" > /dev/null 2>&1; then
    echo "interface $IFACE does not exist."
    exit 1
fi 


MAC=$(GetMAC "$IFACE")
IPV4=$(GetIP -4 "$IFACE")
IPV4_GW=$(GetGateway -4 "$IFACE")
IPV6=$(GetIP -6 "$IFACE")
IPV6_GW=$(GetGateway -6 "$IFACE")

CONF=$(cat <<EOF
[Match]
MACAddress=$MAC
Type=ether

[Link]
RequiredForOnline=yes

[Route]
GatewayOnLink=yes

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


[ "$DHCP" -eq 0 ] && CONF=$(cat <<EOF
[Match]
MACAddress=$MAC
Type=ether

[Link]
RequiredForOnline=yes

[Route]
GatewayOnLink=yes

[Network]
Address=$IPV4
${IPV4_GW:+Gateway=$IPV4_GW}
IPv6AcceptRA=false
${IPV6:+Address=$IPV6}
${IPV6_GW:+Gateway=$IPV6_GW}
EOF
)


FILENAME="/etc/systemd/network/$IFACE.network"
echo "$CONF" > "$FILENAME"

mv /etc/network/interfaces /etc/network/interfaces1.bak 2> /dev/null
systemctl disable networking.service --now
systemctl enable systemd-networkd.service

cat "$FILENAME"
echo "need: systemctl restart systemd-networkd.service" 
