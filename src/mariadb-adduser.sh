#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/mariadb-adduser.sh) 
###############################################################################

# 输入新用户名
read -p "New username: " NEW_USER

# 输入新用户密码
read -s -p "New user's passwd: " NEW_PASS
echo ""

# 执行 SQL
## https://manpages.debian.org/stable/mariadb-client-core/mariadb.1.en.html
mariadb -u root --abort-source-on-error <<EOF
CREATE USER '${NEW_USER}'@'%' IDENTIFIED BY '${NEW_PASS}';
CREATE DATABASE IF NOT EXISTS \`${NEW_USER}\`;
GRANT ALL PRIVILEGES ON \`${NEW_USER}\`.* TO '${NEW_USER}'@'%';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "done!"
else
    echo "Operation failed!"
    exit 1
fi
