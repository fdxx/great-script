#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/ssh-key.sh)  
###############################################################################

mkdir -p $HOME/.ssh
cp "$HOME/.ssh/authorized_keys" "$HOME/.ssh/authorized_keys.bak" 2> /dev/null
echo 'sssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrQo0HCTTT/zcRxdYi2tGprhzG6BNpuD3ZkRlzshajd river' > "$HOME/.ssh/authorized_keys"

