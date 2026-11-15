#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/update-cfdns.sh) --zone_id= --cf_token= --domain= --content=
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
            apt-get update
            APT_UPDATED=1
        fi
        apt-get install "$packname" -y
    fi

    return 0
}

function CheckResult()
{
    local SUCCESS
    SUCCESS=$(jq -r '.success' <<< "$1")

    if [[ "$SUCCESS" == "true" ]]; then
        return 0
    fi

    printf '%s\n' "$1" | jq . >&2
    return 1
}

CheckInstCmd "jq"
ZONE_ID=$(GetArgValueEx "zone_id")
CF_TOKEN=$(GetArgValueEx "cf_token")
DOMAIN=$(GetArgValueEx "domain")
CONTENT=$(GetArgValueEx "content")
TYPE=$(GetArgValueEx "type" "A")

DATA=$(cat <<EOF
{
    "type": "$TYPE",
    "content": "$CONTENT"
}
EOF
)

## 不用 -f：HTTP 4xx 时也要拿到响应体，交给 CheckResult 打印错误
RESULT=$(curl -sSL -G "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" --data-urlencode "type=$TYPE" --data-urlencode "name=$DOMAIN" -H "Authorization: Bearer $CF_TOKEN" -H "Content-Type: application/json")
CheckResult "$RESULT"
RECORD_ID=$(jq -er '.result[0].id' <<< "$RESULT") || { echo "Error: record $TYPE $DOMAIN not found" >&2; exit 1; }
OLD_CONTENT=$(jq -r '.result[0].content' <<< "$RESULT")

RESULT=$(curl -sSL "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" -X PATCH -H 'Content-Type: application/json' -H "Authorization: Bearer $CF_TOKEN" -d "$DATA")
CheckResult "$RESULT"
DOMAIN=$(jq -r '.result.name' <<< "$RESULT")
NEW_CONTENT=$(jq -r '.result.content' <<< "$RESULT")

printf '%s\n' "$RESULT" | jq .
echo "$DOMAIN: $OLD_CONTENT => $NEW_CONTENT"
echo 'done!'
