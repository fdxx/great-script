#!/bin/bash

set -euo pipefail

###############################################################################
###     bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nezha-update.sh)
###############################################################################


if [ $# != 1 ]
then
   echo "Use $(basename "$0") <agent|dash>"
   exit 1;
fi


function UpdateAgent()
{
    wget -O "$WORK_DIR/nezha-agent.zip" "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip"
    unzip -o "$WORK_DIR/nezha-agent.zip" -d "$WORK_DIR"
    cp "$HOME/apps/nezha/agent/nezha-agent" "$HOME/apps/nezha/agent/nezha-agent.bak"
    install -m755 "$WORK_DIR/nezha-agent" "$HOME/apps/nezha/agent/nezha-agent"
    "$HOME/apps/nezha/agent/nezha-agent" -v
    echo "✅done! Need restart nezha-agent"
}

function UpdateDash()
{
    wget -O "$WORK_DIR/dashboard.zip" "https://github.com/nezhahq/nezha/releases/latest/download/dashboard-linux-amd64.zip"
    unzip -o "$WORK_DIR/dashboard.zip" -d "$WORK_DIR"
    cp "$HOME/apps/nezha/dash/nezha-dash" "$HOME/apps/nezha/dash/nezha-dash.bak"
    install -m755 "$WORK_DIR/dashboard-linux-amd64" "$HOME/apps/nezha/dash/nezha-dash"
    "$HOME/apps/nezha/dash/nezha-dash" -v
    echo "✅done! Need restart nezha-dash"
}

case "$1" in
    agent|dash) ;;
    *) echo "Use $(basename "$0") <agent|dash>" >&2; exit 1 ;;
esac

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT

if [ "$1" = agent ]; then
    UpdateAgent
else
    UpdateDash
fi

echo 'done!'
