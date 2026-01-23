#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/tcp-optimize.sh) --bbr=1
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

BBR=$(GetArgValueEx "bbr") || exit 1

if [ -f /etc/sysctl.conf ]; then
    sed -i "/^net.ipv4.tcp_slow_start_after_idle/d" /etc/sysctl.conf
    sed -i "/^net.ipv4.tcp_window_scaling/d" /etc/sysctl.conf
    sed -i "/^net.core.netdev_max_backlog/d" /etc/sysctl.conf
    sed -i "/^net.core.rmem_max/d" /etc/sysctl.conf
    sed -i "/^net.core.wmem_max/d" /etc/sysctl.conf
    sed -i "/^net.ipv4.tcp_rmem/d" /etc/sysctl.conf
    sed -i "/^net.ipv4.tcp_wmem/d" /etc/sysctl.conf
fi

cat <<'EOF' > /etc/sysctl.d/90-tcp-optimize.conf
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.core.netdev_max_backlog = 1500
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.tcp_rmem = 4096 131072 33554432
net.ipv4.tcp_wmem = 4096 131072 33554432
EOF


if (( "$BBR" > 0 )); then
    if [ -f /etc/sysctl.conf ]; then
        sed -i "/^net.core.default_qdisc/d" /etc/sysctl.conf
        sed -i "/^net.ipv4.tcp_congestion_control/d" /etc/sysctl.conf
    fi
    echo 'net.core.default_qdisc = fq' >> /etc/sysctl.d/90-tcp-optimize.conf
    echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.d/90-tcp-optimize.conf
fi

sysctl -p /etc/sysctl.d/90-tcp-optimize.conf
