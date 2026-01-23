#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nezha-agent.sh)
###############################################################################

## GetArgValueEx <key> [defvalue]
## ./script --key=value
g_args=("$@")
function GetArgValueEx1()
{
    local key="$1"

    for arg in "${g_args[@]}"
    do
        if [[ "$arg" == "$key="* ]]
        then
            echo "${arg#*=}"
            return 0
        fi
    done

    if (( "$#" > 1 )); then
        echo "$2"
        return 0
    fi

    echo "Error: Unable to find arg: $key" >&2
    return 1
}

NZ_SERVER=$(GetArgValueEx1 "NZ_SERVER") || exit 1
NZ_CLIENT_SECRET=$(GetArgValueEx1 "NZ_CLIENT_SECRET") || exit 1
NZ_TLS=$(GetArgValueEx1 "NZ_TLS" "true")
NZ_UUID=$(cat /proc/sys/kernel/random/uuid)
NZ_UUID=$(GetArgValueEx1 "NZ_UUID" "$NZ_UUID")


mkdir -p "$HOME/apps/nezha/agent"
cd "$HOME/apps/nezha/agent"

wget -O "nezha-agent.zip" "https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip" || exit 1
unzip nezha-agent.zip

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

chmod +x nezha-agent
./nezha-agent -v

rm -rf nezha-agent.zip
