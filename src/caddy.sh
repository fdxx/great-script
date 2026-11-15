#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/caddy.sh)
###############################################################################

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

CheckInstCmd "jq"
VERSION=$(curl -fsSL "https://api.github.com/repos/fdxx/caddy_builder/releases/latest" | jq -er '.assets[] | select(.name | endswith("_linux_amd64.tar.gz")) | .browser_download_url')

mkdir -p "$HOME/apps/caddy"
cd "$HOME/apps/caddy"
WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/caddy.tar.gz" "$VERSION"
tar -xf "$WORK_DIR/caddy.tar.gz" -C "$WORK_DIR"
install -m755 "$WORK_DIR/caddy" caddy
./caddy version

cat <<'EOF' > caddyfile.example
{
	auto_https disable_redirects
	admin off
	log {
		level ERROR
	}
}

https://www.exp.com:10000 {
	root * /path/to/www.exp.com
	file_server
	tls {
		dns cloudflare {env.CF_Token}
	}
}

https://www.exp.com:10001 {
	respond "Hello World!" 200
	tls {
		dns cloudflare {env.CF_Token}
	}
}
EOF

echo 'done!'
