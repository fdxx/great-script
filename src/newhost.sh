#!/bin/bash

###############################################################################
###    bash <(busybox wget -qO - https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/newhost.sh) --dns=8.8.4.4 --aptsource=http://deb.debian.org --sshport=22
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

## DNS
DNS=$(GetArgValueEx "dns" "8.8.4.4")
cp /etc/resolv.conf /etc/resolv.conf.bak
echo "nameserver $DNS" > /etc/resolv.conf

## Import system information variables
source /etc/os-release
# PRETTY_NAME="Debian GNU/Linux 13 (trixie)"
# NAME="Debian GNU/Linux"
# VERSION_ID="13"
# VERSION="13 (trixie)"
# VERSION_CODENAME=trixie
# DEBIAN_VERSION_FULL=13.2
# ID=debian
# HOME_URL="https://www.debian.org/"
# SUPPORT_URL="https://www.debian.org/support"
# BUG_REPORT_URL="https://bugs.debian.org/"

## sources.list
## http://mirrors.aliyun.com
## https://mirrors.tencent.com
## http://deb.debian.org
APT_SOURCE=$(GetArgValueEx "aptsource" "http://deb.debian.org")
cp /etc/apt/sources.list /etc/apt/sources.list.bak
cat <<EOF > /etc/apt/sources.list
deb $APT_SOURCE/debian/ $VERSION_CODENAME main non-free-firmware
deb $APT_SOURCE/debian/ $VERSION_CODENAME-updates main non-free-firmware
deb $APT_SOURCE/debian-security/ $VERSION_CODENAME-security main
EOF


## Install common software
apt-get update && apt-get install lsb-release curl wget git zip gnupg ca-certificates bind9-dnsutils vim lsof netcat-openbsd mtr-tiny jq -y || exit 1
if (( "$VERSION_ID" > 12 )); then
    apt-get install fastfetch -y || exit 1
fi


## authorized_keys
bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/ssh-key.sh) || exit 1

## sshd_config
## https://manpages.debian.org/stable/openssh-server/sshd_config.5.en.html
SSH_PORT=$(GetArgValueEx "sshport" 22)
SSH_KBDAUTH=ChallengeResponseAuthentication 
if (( "$VERSION_ID" > 11 )); then
    SSH_KBDAUTH=KbdInteractiveAuthentication
fi

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat <<EOF > /etc/ssh/sshd_config
Port $SSH_PORT
UsePAM yes
$SSH_KBDAUTH no
PermitRootLogin yes
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 15
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

## change motd
cp /etc/motd /etc/motd.bak
echo "" > /etc/motd
cat <<'EOF' > /etc/update-motd.d/20-showversion
#!/bin/bash
source /etc/os-release
echo "$PRETTY_NAME $DEBIAN_VERSION_FULL"
EOF
chmod +x /etc/update-motd.d/20-showversion


## hostname
cp /etc/hostname /etc/hostname.bak
echo "debian" > /etc/hostname
hostname debian


## hosts
cp /etc/hosts /etc/hosts.bak
cat <<'EOF' > /etc/hosts
127.0.0.1       localhost
127.0.1.1       debian debian.lan
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF


## timesync
bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/timesync.sh) || exit 1

## Turn off auto selection after pasting
sed -i "/enable-bracketed-paste/d" /etc/profile
sed -i "/enable-bracketed-paste/d" /etc/inputrc
echo 'set enable-bracketed-paste off' >> /etc/inputrc


## IPv4 preferred
sed -i "/^precedence ::ffff:0:0/d" /etc/gai.conf
echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf


## safe rm command
bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/srm-inst.sh) || exit 1


## Root user terminal colors
## extracted from normal users
cp /root/.bashrc /root/.bashrc.bak
cat <<'EOF' > /root/.bashrc
# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

## Command auto completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
EOF

systemctl restart sshd
[ -f /usr/bin/fastfetch ] && fastfetch
echo "done!"
