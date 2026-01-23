#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nft.sh) --port_allow="22,443,11000-11020"
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

## <-4|-6>
function GetSelfIP()
{
    echo "$(curl $1 -s ip.sb)"
    return 0
}

## <-4|-6> <ip>
function GetNeighRange()
{
    local FAMILY=$1
    local IP=$2

    if [ -z "$IP" ]; then
        echo ""
        return 0
    fi
    
    local RESULT=$(ip $FAMILY a | grep "$IP" | awk '{print $2}')
    if [ -n "$RESULT" ]; then
        echo "$RESULT"
        return 0
    fi

    if [[ "$FAMILY" == "-4" ]]; then
        echo "${IP%.*}.0/24"
        return 0
    fi

    echo ""
    return 0
}

## <-4|-6>
function GetGatway()
{
    local RESULT=$(ip $1 route show default | awk -F"via " '{print $2}' | awk '{print $1}')
    echo "$RESULT"
    return 0
}

function GetSpamIP()
{
    IPSUM_V4='101.36.104.0/24, 103.163.119.0/24, 103.252.73.0/24, 103.48.192.0/24, 114.111.54.0/24, 115.241.83.0/24, 117.6.44.0/24, 117.91.186.0/24, 12.156.67.0/24, 128.14.167.0/24, 128.14.227.0/24, 128.1.47.0/24, 129.45.84.0/24, 142.93.27.0/24, 143.20.185.0/24, 14.63.196.0/24, 14.63.217.0/24, 150.241.115.0/24, 152.32.250.0/24, 159.65.31.0/24, 160.174.129.0/24, 161.49.89.0/24, 162.142.125.0/24, 163.5.148.0/24, 164.177.31.0/24, 167.71.104.0/24, 167.94.138.0/24, 167.94.146.0/24, 171.104.143.0/24, 172.105.128.0/24, 178.128.63.0/24, 178.251.140.0/24, 179.32.33.0/24, 179.43.184.0/24, 181.212.81.0/24, 182.43.235.0/24, 183.82.126.0/24, 185.138.88.0/24, 185.242.247.0/24, 185.246.130.0/24, 186.96.145.0/24, 186.96.151.0/24, 189.217.130.0/24, 190.124.153.0/24, 192.210.160.0/24, 193.106.245.0/24, 193.32.162.0/24, 193.46.255.0/24, 196.251.100.0/24, 197.227.8.0/24, 197.5.145.0/24, 198.12.114.0/24, 199.45.154.0/24, 199.45.155.0/24, 200.118.99.0/24, 200.69.236.0/24, 200.73.135.0/24, 202.51.214.0/24, 203.19.35.0/24, 206.168.34.0/24, 210.114.22.0/24, 213.55.85.0/24, 220.80.223.0/24, 222.107.156.0/24, 2.57.121.0/24, 27.254.137.0/24, 27.79.2.0/24, 3.130.96.0/24, 3.131.215.0/24, 3.137.73.0/24, 3.149.59.0/24, 34.142.110.0/24, 36.67.70.0/24, 36.91.166.0/24, 4.185.68.0/24, 45.119.81.0/24, 45.148.10.0/24, 45.156.129.0/24, 45.79.128.0/24, 45.79.181.0/24, 45.81.23.0/24, 46.161.50.0/24, 50.84.211.0/24, 5.101.64.0/24, 51.158.120.0/24, 5.187.97.0/24, 51.89.166.0/24, 57.128.190.0/24, 61.245.11.0/24, 61.50.119.0/24, 61.80.179.0/24, 62.169.238.0/24, 64.227.97.0/24, 71.6.135.0/24, 71.6.158.0/24, 71.6.199.0/24, 79.99.40.0/24, 80.82.77.0/24, 80.94.92.0/24, 82.199.197.0/24, 83.168.107.0/24, 86.54.31.0/24, 88.147.30.0/24, 89.185.84.0/24, 92.27.101.0/24, 93.174.95.0/24, 94.141.161.0/24, 94.254.0.0/24, 95.167.225.0/24'

    Latency=$(ping -c 3 -i 0.5 1.0.0.1 | tail -1 | awk -F'/' '{printf "%d\n", $5}')
    if (( $Latency > 20 )); then
        echo "$IPSUM_V4"
        return 0
    fi

    IPSUM_V4_NEW=$(curl -fsSL https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt | grep -v "#" | grep -v -E "\s[1-6]$" | cut -f 1 | awk -F. '{print $1"."$2"."$3".0/24"}' | sort -u | paste -sd ',' - | sed 's/,/, /g')
    echo "$IPSUM_V4_NEW"
    return 0
}

PORT_ALLOW=$(GetArgValueEx "port_allow") || exit 1
NFTCONF=$(GetArgValueEx "nftconf" "/etc/nftables.conf")

SELF_V4=$(GetSelfIP -4)
BUFFER=$(GetGatway -4)
[ -n "$BUFFER" ] && SELF_V4="$SELF_V4, $BUFFER"

SELF_V6="100::1"
BUFFER=$(GetSelfIP -6)
[ -n "$BUFFER" ] && SELF_V6="$BUFFER"
BUFFER=$(GetGatway -6)
[ -n "$BUFFER" ] && SELF_V6="$SELF_V6, $BUFFER"


SPAM_V4='66.132.159.0/24, 162.142.125.0/24, 167.94.138.0/24, 167.94.145.0/24, 167.94.146.0/24, 167.248.133.0/24, 199.45.154.0/24, 199.45.155.0/24, 206.168.34.0/24, 206.168.35.0/24'
BUFFER=$(GetNeighRange -4 "$(GetSelfIP -4)")
[ -n "$BUFFER" ] && SPAM_V4="$BUFFER, $SPAM_V4"
BUFFER=$(GetSpamIP)
[ -n "$BUFFER" ] && SPAM_V4="$SPAM_V4, $BUFFER"


SPAM_V6='2602:80d:1000:b0cc:e::/80, 2620:96:e000:b0cc:e::/80, 2602:80d:1003::/112, 2602:80d:1004::/112'
BUFFER=$(GetNeighRange -6 "$(GetSelfIP -6)")
[ -n "$BUFFER" ] && SPAM_V6="$BUFFER, $SPAM_V6"

OLDCONF="${NFTCONF}.$(date '+%Y%m%d%H%M%S').bak"
cp "$NFTCONF" "$OLDCONF"
cat <<EOF > "$NFTCONF"
#!/usr/sbin/nft -f

flush ruleset

table inet main {
    set self_v4 {
        type ipv4_addr
        elements = {
            $SELF_V4
        }
    }

    set self_v6 {
        type ipv6_addr
        elements = {
            $SELF_V6
        }
    }

    set spam_v4 {
        type ipv4_addr
        flags interval
        auto-merge
        elements = {
            $SPAM_V4
        }
    }

    set spam_v6 {
        type ipv6_addr
        flags interval
        auto-merge
        elements = {
            $SPAM_V6
        }
    }

    set ports_allowed {
        type inet_service
        flags interval
        elements = { $PORT_ALLOW }
    }

    chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        ## iifname ens18 meta l4proto { tcp, udp } th dport 1234-5678 dnat ip to 192.168.0.1
    }

    chain input {
        type filter hook input priority filter; policy drop;
        iifname "lo" accept
        ct state { established, related } accept
        fib saddr type local accept
        ip6 saddr fe80::/10 accept
        meta l4proto ipv6-icmp accept

        ip saddr @self_v4 accept
        ip6 saddr @self_v6 accept

        ip saddr @spam_v4 log prefix "SpamReject: " group 10 drop
        ip6 saddr @spam_v6 log prefix "SpamReject: " group 10 drop
        meta l4proto { tcp, udp } th dport @ports_allowed accept
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
        ## ct state { established, related } accept
        ## ct status dnat accept
        ## ip saddr @snat_v4 accept
    }

    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        ## ct status dnat masquerade
    }
}
EOF

if ! command -v ulogd >/dev/null 2>&1; then
    apt update && apt install ulogd2 -y
fi

cp /etc/ulogd.conf /etc/ulogd.conf.bak
cat <<'EOF' > /etc/ulogd.conf
[global]
logfile="syslog"
loglevel=3
stack=log10:NFLOG,base1:BASE,ifi1:IFINDEX,ip2str1:IP2STR,print1:PRINTPKT,emu10:LOGEMU

[log10]
group=10
[emu10]
file="/var/log/ulog/drop.log"
sync=1
EOF

systemctl enable ulogd2
systemctl restart ulogd2

systemctl enable nftables
nft -c -f "$NFTCONF"
git --no-pager diff "$OLDCONF" "$NFTCONF"
echo "need run: systemctl restart nftables"
