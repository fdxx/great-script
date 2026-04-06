#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/sptest_inst.sh)
###############################################################################

cat <<'EOF' > /usr/bin/sptest
#!/bin/bash

if [[ "$1" == "up" ]]; then
    set -x
    curl -o /dev/null -X POST -T - https://speed.cloudflare.com/__up < /dev/urandom
    set +x
    exit 0
fi

set -x
curl -o /dev/null -H "referer: https://speed.cloudflare.com/" https://speed.cloudflare.com/__down?bytes=1048576000
set +x
EOF

chmod +x /usr/bin/sptest


