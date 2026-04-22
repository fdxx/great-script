#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/srm-inst.sh)
###############################################################################

## srm命令可以将文件移动到垃圾桶，作为rm命令的替代品
wget -O /usr/bin/srm https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/srm.sh || exit 1
chmod +x /usr/bin/srm

systemctl disable trash-clean.service --now 2> /dev/null
systemctl disable trash-clean.timer --now 2> /dev/null

cat <<EOF > /etc/systemd/system/trash-clean.service
[Unit]
Description=Clean all users trash directories

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/bin/srm -ca

[Install]
WantedBy=multi-user.target
EOF

## 每天6点清理垃圾桶
cat <<EOF > /etc/systemd/system/trash-clean.timer
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
