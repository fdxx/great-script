#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/update-cfdns) --zone_id= --cf_token= --domain= --content=
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

## CheckInstCmd <cmd> [packname]
function CheckInstCmd()
{
    if (( "$#" < 1 )); then
        return 1
    fi

    : "${APT_UPDATED:=0}"

    local cmd="$1"
    local packname="${2:-$1}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        if (( APT_UPDATED == 0 )); then
            apt-get update && APT_UPDATED=1 || return 1
        fi
        apt-get install "$packname" -y || return 1
    fi

    return 0
}

function CheckResult()
{
    SUCCESS=$(echo "$1" | jq -r '.success')

    if [[ "$SUCCESS" == "true" ]]; then
        return 0
    fi

    echo "$1" | jq . >&2
    return 1
}

CheckInstCmd "jq" || exit 1
ZONE_ID=$(GetArgValueEx "zone_id") || exit 1
CF_TOKEN=$(GetArgValueEx "cf_token") || exit 1
DOMAIN=$(GetArgValueEx "domain") || exit 1
CONTENT=$(GetArgValueEx "content") || exit 1
TYPE=$(GetArgValueEx "type" "A")

DATA=$(cat <<EOF
{
    "type": "$TYPE",
    "content": "$CONTENT"
}
EOF
)

RESULT=$(curl -fsSL "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=$TYPE&name=$DOMAIN" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json") || exit 1
CheckResult "$RESULT" || exit 1
RECORD_ID=$(echo "$RESULT" | jq -r '.result[0].id')
OLD_CONTENT=$(echo "$RESULT" | jq -r '.result[0].content')


RESULT=$(curl -fsSL https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID -X PATCH -H 'Content-Type: application/json' -H "Authorization: Bearer $CF_TOKEN" -d "$DATA") || exit 1
CheckResult "$RESULT" || exit 1
DOMAIN=$(echo "$RESULT" | jq -r '.result.name')
NEW_CONTENT=$(echo "$RESULT" | jq -r '.result.content')

echo "$RESULT" | jq .
echo "$DOMAIN: $OLD_CONTENT => $NEW_CONTENT"
