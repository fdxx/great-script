#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nezha-agent.sh)
###############################################################################

## GetArgValueEx <key> [defvalue]
## ./script --key=value
g_args=("$@")
function GetArgValueEx()
{
    local key="$1"

    for arg in "${g_args[@]}"
    do
        if [[ "$arg" == "$key="* || "$arg" == "--$key="* ]]
        then
            printf '%s\n' "${arg#*=}"
            return 0
        fi
    done

    if (( "$#" > 1 )); then
        printf '%s\n' "$2"
        return 0
    fi

    echo "Error: Unable to find arg: $key" >&2
    return 1
}

NZ_SERVER=$(GetArgValueEx "NZ_SERVER")
NZ_CLIENT_SECRET=$(GetArgValueEx "NZ_CLIENT_SECRET")
NZ_TLS=$(GetArgValueEx "NZ_TLS" "true")

mkdir -p "$HOME/apps/nezha/agent"
cd "$HOME/apps/nezha/agent"

## 重装时沿用旧 UUID，避免面板出现新机器
if [ -f config.yaml ]; then
    NZ_UUID=$(awk '/^uuid:/ {print $2}' config.yaml)
else
    NZ_UUID=$(cat /proc/sys/kernel/random/uuid)
fi
NZ_UUID=$(GetArgValueEx "NZ_UUID" "$NZ_UUID")

WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/nezha-agent.zip" "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip"
unzip -o "$WORK_DIR/nezha-agent.zip" -d "$WORK_DIR"
install -m755 "$WORK_DIR/nezha-agent" nezha-agent

cat <<EOF > config.yaml
client_secret: $NZ_CLIENT_SECRET
uuid: $NZ_UUID
server: $NZ_SERVER
tls: $NZ_TLS
debug: false
disable_auto_update: true
disable_command_execute: true
disable_force_update: true
disable_nat: true
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 3
self_update_period: 0
skip_connection_count: false
skip_procs_count: false
temperature: false
use_gitee_to_upgrade: false
use_ipv6_country_code: false
EOF

./nezha-agent -v
echo 'done!'
