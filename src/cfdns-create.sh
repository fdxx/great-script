#!/bin/bash

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
        if [[ "$arg" == "--$key="* ]]
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

ZONE_ID=$(GetArgValueEx "zone_id") || exit 1
CF_TOKEN=$(GetArgValueEx "cf_token") || exit 1
DOMAIN=$(GetArgValueEx "domain") || exit 1
CONTENT=$(GetArgValueEx "content") || exit 1
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

RESULT=$(curl -fsSL https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records -H 'Content-Type: application/json' -H "Authorization: Bearer $CF_TOKEN" -d "$DATA") || exit 1

if command -v "jq" >/dev/null 2>&1; then
    echo "$RESULT" | jq .
else
    echo "$RESULT"
    echo ""
fi
