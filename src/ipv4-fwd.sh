#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/ipv4-fwd.sh)
###############################################################################

[ -f /etc/sysctl.conf ] && sed -i "/^net.ipv4.ip_forward/d" /etc/sysctl.conf
[ -f /etc/sysctl.d/90-fwd.conf ] && sed -i "/^net.ipv4.ip_forward/d" /etc/sysctl.d/90-fwd.conf

echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.d/90-fwd.conf
sysctl -p /etc/sysctl.d/90-fwd.conf
