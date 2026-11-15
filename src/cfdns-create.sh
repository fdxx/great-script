#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/cfdns-create.sh) --zone_id= --cf_token= --domain= --content=
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

ZONE_ID=$(GetArgValueEx "zone_id")
CF_TOKEN=$(GetArgValueEx "cf_token")
DOMAIN=$(GetArgValueEx "domain")
CONTENT=$(GetArgValueEx "content")
TYPE=$(GetArgValueEx "type" "A")

DATA=$(cat <<EOF
{
    "name": "$DOMAIN",
    "ttl": 1,
    "type": "$TYPE",
    "content": "$CONTENT",
    "proxied": false
}
EOF
)

RESULT=$(curl -sSL "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" -H 'Content-Type: application/json' -H "Authorization: Bearer $CF_TOKEN" -d "$DATA")

if command -v "jq" >/dev/null 2>&1; then
    echo "$RESULT" | jq .
else
    echo "$RESULT"
    echo ""
fi
echo 'done!'
