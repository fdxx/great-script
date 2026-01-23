#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/disable-ipv6.sh)
###############################################################################

if [ -f /etc/sysctl.conf ]; then
    sed -i "/^net.ipv6.conf.all.disable_ipv6/d" /etc/sysctl.conf
    sed -i "/^net.ipv6.conf.default.disable_ipv6/d" /etc/sysctl.conf
fi

cat <<'EOF' > /etc/sysctl.d/91-disable_ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

sysctl -p /etc/sysctl.d/91-disable_ipv6.conf
