#!/bin/bash

###############################################################################
###    source <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/node.sh)
###############################################################################

bash <(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh) || exit 1
source "$HOME/.bashrc"
nvm install --lts
node -v
npm -v 


