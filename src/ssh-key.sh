#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/ssh-key.sh)  
###############################################################################

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -f "$HOME/.ssh/authorized_keys" ]; then
    cp "$HOME/.ssh/authorized_keys" "$HOME/.ssh/authorized_keys.bak"
fi
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrQo0HCTTT/zcRxdYi2tGprhzG6BNpuD3ZkRlzshajd river' > "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
echo 'done!'
