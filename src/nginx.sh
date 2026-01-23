#!/bin/bash

###############################################################################
###    bash <(curl -fsSL https://raw.githubusercontent.com/fdxx/great-script/refs/heads/main/src/nginx.sh) 
###############################################################################

if dpkg -s nginx >/dev/null 2>&1; then
    echo "nginx is already installed."
    exit 1
fi

apt-get update && apt-get install nginx -y || exit 1

mkdir -p /etc/nginx/logs
mkdir -p /etc/nginx/cert
mkdir -p /etc/nginx/webroot/test

cat <<'EOF' > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log "/etc/nginx/logs/error.log" warn;

events {
    worker_connections 1000;
}

http {
    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;

    include mime.types;
    default_type application/octet-stream;
    charset utf-8;

    log_not_found off;

    client_max_body_size 0;
    client_body_timeout 300s;
    client_body_buffer_size 1m;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 5;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    include /etc/nginx/conf.d/*.conf;
}
EOF

cat <<'EOF' > /etc/nginx/ssl_params
## https://ssl-config.mozilla.org/
# ssl_protocols TLSv1.2 TLSv1.3;
# ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
# ssl_ecdh_curve auto;
# ssl_prefer_server_ciphers off;
# ssl_session_timeout 1d;
# ssl_session_cache shared:MozSSL:10m;

ssl_protocols TLSv1.3;
ssl_ecdh_curve X25519:prime256v1:secp384r1;
ssl_prefer_server_ciphers off;
EOF

cat <<'EOF' > /etc/nginx/conf.d/test.conf
server {
    listen 8082;
    server_name _;
    index index.html;
    root /etc/nginx/webroot/test;

    location ~ /\. {
        return 404;
    }

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$ {
        expires 5d;
    }

    location ~ .*\.(js|css)$ {
        expires 12h;
    }

    error_log /etc/nginx/logs/test.error.log warn;
}
EOF

echo '<h1>Welcome to nginx!</h1>' > /etc/nginx/webroot/test/index.html

cat <<'EOF' > /etc/nginx/conf.d/full.conf.example
server {
    listen 80;
    server_name www.exp.com;
    return 301 https://www.exp.com$request_uri;
}
server {
    listen 9443 ssl proxy_protocol;
    ## http2 on;
    server_name www.exp.com;
    index index.html;
    root "/etc/nginx/webroot/www.exp.com";

    ## haproxy proxy_protocol
    ## set_real_ip_from unix:;
    set_real_ip_from 127.0.0.0/8;
    real_ip_header proxy_protocol;

    include ssl_params;
    ssl_certificate "/etc/nginx/cert/www.exp.com/cert.pem";
    ssl_certificate_key "/etc/nginx/cert/www.exp.com/key.pem";

    location ~ /\. {
        return 404;
    }

    location / {
        # First attempt to serve request as file, then as directory,
        # then fall back to displaying a 404.
        try_files $uri $uri/ =404;
    }

    location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$ {
        expires 5d;
    }

    location ~ .*\.(js|css)$ {
        expires 12h;
    }

    location /api/getxx {
        proxy_pass http://127.0.0.1:3005/; 
        include proxy_params;
    }

    error_log "/etc/nginx/logs/www.exp.com.error.log" warn;
}
EOF


[ ! -d /nginxdir ] && ln -s /etc/nginx /nginxdir
[ ! -d "$HOME/nginxdir" ] && ln -s /etc/nginx "$HOME/nginxdir"

systemctl enable nginx
nginx -t || exit 1
systemctl restart nginx
echo "done!"
