#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/ssh-key.sh)  
###############################################################################

mkdir -p $HOME/.ssh
cp "$HOME/.ssh/authorized_keys" "$HOME/.ssh/authorized_keys.bak" 2> /dev/null
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEC9OFOjZx7Z6/fdFbQUvS0X2F2GZhQYp0AyFLR7aSYB river' > "$HOME/.ssh/authorized_keys"

