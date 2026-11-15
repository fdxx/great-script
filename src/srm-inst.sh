#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/srm-inst.sh)
###############################################################################

## srm命令可以将文件移动到垃圾桶，作为rm命令的替代品
WORK_DIR=$(mktemp -d)
trap 'rm -rf -- "$WORK_DIR"' EXIT
wget -O "$WORK_DIR/srm" https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/srm.sh
install -Dm755 "$WORK_DIR/srm" /opt/srm/srm
ln -sfnT /opt/srm/srm /usr/local/bin/srm
rm -fv /usr/bin/srm

if systemctl cat trash-clean.service >/dev/null 2>&1; then
    systemctl disable trash-clean.service --now
fi
if systemctl cat trash-clean.timer >/dev/null 2>&1; then
    systemctl disable trash-clean.timer --now
fi

cat <<'EOF' > /etc/systemd/system/trash-clean.service
[Unit]
Description=Clean all users trash directories

[Service]
Type=oneshot
User=root
ExecStart=/opt/srm/srm -ca

[Install]
WantedBy=multi-user.target
EOF

## 每天6点清理垃圾桶
cat <<'EOF' > /etc/systemd/system/trash-clean.timer
[Unit]
Description=Run trash-clean.service every day

[Timer]
OnCalendar=*-*-* 06:00:00

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable trash-clean.timer
systemctl restart trash-clean.timer
echo 'done!'
