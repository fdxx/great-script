#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/sptest_inst.sh)
###############################################################################

## curl -o /dev/null -X POST -T - https://speed.cloudflare.com/__up < /dev/urandom
## curl -o /dev/null https://speed.cloudflare.com/__down?bytes=1048576000

cat <<'EOF' > /usr/bin/sptest
#!/bin/bash

UPCMD='curl -o /dev/null -X POST -T - https://speed.cloudflare.com/__up < /dev/urandom'
DOWNCMD='curl -o /dev/null https://speed.cloudflare.com/__down?bytes=1048576000'

if [[ "$1" == "up" ]]; then
    echo "$UPCMD"
    eval "$UPCMD"
    exit 0
fi

echo "$DOWNCMD"
$DOWNCMD
EOF

chmod +x /usr/bin/sptest


