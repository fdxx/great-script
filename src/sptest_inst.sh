#!/bin/bash

set -euo pipefail

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/sptest_inst.sh)
###############################################################################

install -d /opt/sptest
cat <<'EOF' > /opt/sptest/sptest
#!/bin/bash

set -euo pipefail

if [[ "${1:-}" == "up" ]]; then
    set -x
    curl -f -o /dev/null -X POST -T - https://speed.cloudflare.com/__up < /dev/urandom
    set +x
    exit 0
fi
set -x
curl -f -o /dev/null -H "referer: https://speed.cloudflare.com/" 'https://speed.cloudflare.com/__down?bytes=1048576000'
set +x
EOF

chmod +x /opt/sptest/sptest
ln -sfnT /opt/sptest/sptest /usr/local/bin/sptest
rm -fv /usr/bin/sptest
echo 'done!'
