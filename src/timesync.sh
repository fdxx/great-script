#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/timesync.sh)  --timezone="Asia/Shanghai" --ntpserver="time.apple.com"
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

TIMEZONE=$(GetArgValueEx "timezone" "Asia/Shanghai")
NTPSERVER=$(GetArgValueEx "ntpserver" "time.apple.com")

timedatectl set-timezone $TIMEZONE

if ! dpkg -s systemd-timesyncd >/dev/null 2>&1; then
    apt-get update && apt-get install systemd-timesyncd -y || exit 1
fi

## https://manpages.debian.org/stable/systemd-timesyncd/timesyncd.conf.5.en.html
cp "/etc/systemd/timesyncd.conf" "/etc/systemd/timesyncd.conf.bak" 2> /dev/null
cat <<EOF > "/etc/systemd/timesyncd.conf"
[Time]
NTP=$NTPSERVER
FallbackNTP=time.windows.com ntp.tencent.com time.apple.com
RootDistanceMaxSec=5
EOF

systemctl restart systemd-timesyncd
systemctl enable systemd-timesyncd
timedatectl set-ntp true 2> /dev/null
timedatectl timesync-status
