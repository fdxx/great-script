#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/mariadb-adduser.sh) 
###############################################################################

# 输入新用户名
read -r -p "New username: " NEW_USER

# 输入新用户密码
read -r -s -p "New user's passwd: " NEW_PASS
echo ""

# 转义 SQL 字符串和数据库标识符，保留密码中的引号、反斜杠。
SQL_USER=${NEW_USER//\'/\'\'}
SQL_PASS=${NEW_PASS//\'/\'\'}
SQL_DATABASE=${NEW_USER//\`/\`\`}

# 执行 SQL
## https://manpages.debian.org/stable/mariadb-client-core/mariadb.1.en.html
mariadb -u root --abort-source-on-error <<EOF
SET SESSION sql_mode = 'NO_BACKSLASH_ESCAPES';
CREATE USER '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASS}';
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "done!"
