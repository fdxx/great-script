#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/fastfetch.sh)
###############################################################################

wget "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz" || exit 1
tar -xf fastfetch-linux-amd64.tar.gz
cp fastfetch-linux-amd64/usr/bin/fastfetch /usr/bin
chmod +x /usr/bin/fastfetch
rm -rf fastfetch-linux-amd64.tar.gz fastfetch-linux-amd64
fastfetch

