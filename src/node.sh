#!/bin/bash

###############################################################################
###    source <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/node.sh)
###############################################################################

NVM_INSTALLER=$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/refs/heads/master/install.sh)
bash -c "$NVM_INSTALLER"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
source "$NVM_DIR/nvm.sh"
nvm install --lts
node -v
npm -v
