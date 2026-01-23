#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/mariadb.sh) 
###############################################################################

if dpkg -s mariadb-server >/dev/null 2>&1; then
    echo "MariaDB Server is already installed."
    exit 1
fi

apt-get update && apt-get install mariadb-server -y || exit 1
mariadb-secure-installation

cat <<'EOF' > /etc/mysql/mariadb.conf.d/99-server.cnf
[mysqld]
skip-name-resolve
bind-address = 0.0.0.0
EOF

systemctl restart mariadb.service
echo "done!"

