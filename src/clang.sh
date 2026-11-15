#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/clang.sh) --purge=1
###############################################################################

## GetArgValueEx <key> [defvalue]
## ./script --key=value
g_args=("$@")
function GetArgValueEx()
{
    local key="$1"

    for arg in "${g_args[@]}"
    do
        if [[ "$arg" == "$key="* || "$arg" == "--$key="* ]]
        then
            printf '%s\n' "${arg#*=}"
            return 0
        fi
    done

    if (( "$#" > 1 )); then
        printf '%s\n' "$2"
        return 0
    fi

    echo "Error: Unable to find arg: $key" >&2
    return 1
}


PURGE=$(GetArgValueEx "purge")
VERSION=$(GetArgValueEx "version" "")
if [ -n "$VERSION" ]; then
    VERSION="-$VERSION"
fi

if (( "$PURGE" > 0 )); then
    apt-get purge "clang*" "llvm*" "lldb*" "lld*" "clangd*" "g++*" "libc++*" -y
    apt-get autoremove --purge -y
fi

apt-get update
apt-get install -y g++-multilib git make "clang${VERSION}" "lldb${VERSION}" "lld${VERSION}" "clangd${VERSION}"

sed -i "\|^export PATH=/usr/lib/llvm-|d" /etc/profile
if [ -n "$VERSION" ]; then
    echo "export PATH=/usr/lib/llvm${VERSION}/bin:\$PATH" >> /etc/profile
fi

sed -i "/^export CC=/d" /etc/profile
sed -i "/^export CXX=/d" /etc/profile
echo 'export CC=clang' >> /etc/profile
echo 'export CXX=clang++' >> /etc/profile
echo "-----"
"clang${VERSION}" -v
echo 'done!'
