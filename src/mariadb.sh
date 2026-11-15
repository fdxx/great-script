#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/mariadb.sh) 
###############################################################################

function CheckPkgOrExit()
{
    local pkg="$1" status
    status=$(dpkg-query -W -f='${db:Status-Status}' "$pkg" 2>/dev/null || true)
    if [[ "$status" == "installed" ]]; then
        echo "$pkg has already installed by Debian package!"
        exit 0
    fi
}

CheckPkgOrExit mariadb-server

apt-get update
apt-get install mariadb-server -y

cat <<'EOF' > /etc/mysql/mariadb.conf.d/99-server.cnf
[mysqld]
skip-name-resolve
bind-address = 0.0.0.0
EOF

systemctl restart mariadb.service
echo "done!"
