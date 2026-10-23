#!/bin/bash

###############################################################################
###     bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nezha-update.sh)
###############################################################################


if [ $# != 1 ]
then
   echo "Use $(basename "$0") <agent|dash>"
   exit 1;
fi

set -eux

function UpdateAgent()
{
    wget -O /tmp/nzdl/nezha-agent_linux_amd64 "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip"
    unzip /tmp/nzdl/nezha-agent_linux_amd64 -d /tmp/nzdl
    mv ~/apps/nezha/agent/nezha-agent ~/apps/nezha/agent/nezha-agent.bak
    mv /tmp/nzdl/nezha-agent ~/apps/nezha/agent/nezha-agent
    chmod +x ~/apps/nezha/agent/nezha-agent
    ~/apps/nezha/agent/nezha-agent -v
    echo "✅done! Need restart nezha-agent"
}

function UpdateDash()
{
    wget -O /tmp/nzdl/dashboard-linux-amd64.zip "https://github.com/nezhahq/nezha/releases/latest/download/dashboard-linux-amd64.zip"
    unzip /tmp/nzdl/dashboard-linux-amd64.zip -d /tmp/nzdl
    mv ~/apps/nezha/dash/nezha-dash ~/apps/nezha/dash/nezha-dash.bak
    mv /tmp/nzdl/dashboard-linux-amd64 ~/apps/nezha/dash/nezha-dash
    chmod +x ~/apps/nezha/dash/nezha-dash
    ~/apps/nezha/dash/nezha-dash -v
    echo "✅done! Need restart nezha-dash"
}

rm -rf /tmp/nzdl
mkdir /tmp/nzdl

if [ $1 = 'agent' ]
then
    UpdateAgent
elif [ $1 = 'dash' ]
then
    UpdateDash
fi

rm -rf /tmp/nzdl

