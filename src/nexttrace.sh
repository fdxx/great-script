#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nexttrace.sh)
###############################################################################

wget -O "nexttrace" "https://github.com/nxtrace/NTrace-core/releases/latest/download/nexttrace_linux_amd64" || exit 1
chmod +x nexttrace
mv nexttrace /usr/bin
nexttrace --version

