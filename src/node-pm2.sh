#!/bin/bash

###############################################################################
###    source <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/node-pm2.sh)
###############################################################################

if ! command -v node >/dev/null 2>&1; then
    NODE_INSTALLER=$(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/node.sh)
    eval "$NODE_INSTALLER"
fi

npm install pm2 -g
pm2 startup
pm2 install pm2-logrotate
pm2 set pm2-logrotate:rotateInterval '1 0 * * 3'
echo 'done!'
