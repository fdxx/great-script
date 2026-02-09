#!/bin/bash

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


PURGE=$(GetArgValueEx "purge") || exit 1
VERSION=$(GetArgValueEx "version" "")
[ -n "$VERSION" ] && VERSION="-$VERSION"

if (( "$PURGE" > 0 )); then
    apt-get purge "clang*" "llvm*" "lldb*" "lld*" "clangd*" "g++*" -y || exit 1
    apt-get autoremove --purge -y || exit 1
fi

apt-get update && apt-get install -y g++-multilib git make clang${VERSION} lldb${VERSION} lld${VERSION} clangd${VERSION} || exit 1

sed -i "\|^export PATH=/usr/lib/llvm-|d" /etc/profile
if [ -n "$VERSION" ]; then
    echo "export PATH=/usr/lib/llvm${VERSION}/bin:\$PATH" >> /etc/profile
fi

sed -i "/^export CC=/d" /etc/profile
sed -i "/^export CXX=/d" /etc/profile
echo 'export CC=clang' >> /etc/profile
echo 'export CXX=clang++' >> /etc/profile
source /etc/profile
clang -v
