#!/bin/bash

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
            apt-get update && APT_UPDATED=1 || return 1
        fi
        apt-get install "$packname" -y || return 1
    fi

    return 0
}

CheckInstCmd "jq" || exit 1
VERSION=$(curl -fsSL "https://api.github.com/repos/fdxx/caddy_builder/releases/latest" | jq -r '.assets[] | select(.browser_download_url | test("_linux_amd64.tar.gz")).browser_download_url') || exit 1

mkdir -p "$HOME/apps/caddy"
cd "$HOME/apps/caddy"
wget -O caddy.tar.gz "$VERSION" || exit 1
tar -xf caddy.tar.gz
chmod +x caddy
./caddy version
rm -rf caddy.tar.gz

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
