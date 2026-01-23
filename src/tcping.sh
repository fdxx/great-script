#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/tcping.sh)
###############################################################################

wget -O "tcping.tar.gz" "https://github.com/pouriyajamshidi/tcping/releases/latest/download/tcping-linux-amd64-static.tar.gz" || exit 1
tar -xf tcping.tar.gz
chmod +x tcping
mv tcping /usr/bin
rm -rf tcping.tar.gz
tcping -v

