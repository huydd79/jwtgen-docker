#!/bin/bash
set -e # Exit on error

# Configuration
CERT_CONF="/tmp/cert.conf"
PRIV_KEY="/etc/ssl/private/jwtgen.key"
PUB_CERT="/etc/ssl/certs/jwtgen.crt"
KID_FILE="/etc/jwtgen/kid"

# Generate OpenSSL config
cat <<EOF > $CERT_CONF
[req]
distinguished_name = HUYDO-LAB
prompt = no
[HUYDO-LAB]
C = VN
ST = Hanoi
L = Hanoi
O = huydo.net
CN = HUYDO-LAB
EOF

echo "--- Generating RSA Key Pair ---"
# Generate private key directly without intermediate passphrase files for better security
openssl genrsa -out $PRIV_KEY 4096
openssl req -new -x509 -days 3650 -key $PRIV_KEY -out $PUB_CERT -config $CERT_CONF
rm -f $CERT_CONF
chmod 600 $PRIV_KEY

# Generate Kid from hostname
KID=$(hostname | sha1sum | awk '{print $1}')
echo -n "$KID" > "$KID_FILE"

# Update Header template with new KID
jq ".kid=\"$KID\"" /etc/jwtgen/jwt_header.json > /tmp/header.tmp && mv /tmp/header.tmp /etc/jwtgen/jwt_header.json

# Convert to JWKS
/usr/local/bin/pem2jwks.py "$PUB_CERT" "$KID" > /etc/jwtgen/jwt.pub

echo "JWT Public Key (JWKS):"
cat /etc/jwtgen/jwt.pub

# Initial JWT Generation
echo "Generating initial JWT..."
/usr/local/bin/jwtgen.sh /etc/jwtgen/jwt_header.json /etc/jwtgen/jwt_payload.json $PRIV_KEY > /var/run/jwtgen/jwt

# Get expiration delta from env or use default
EXP_DELTA=${JWT_EXPIRE:-3600}

# Calculating refresh interval (90% of expiration time)
REFRESH_SLEEP=$(( EXP_DELTA * 90 / 100 ))

echo "Initial JWT generation (Expire: ${EXP_DELTA}s)..."
/usr/local/bin/jwtgen.sh /etc/jwtgen/jwt_header.json /etc/jwtgen/jwt_payload.json /etc/ssl/private/jwtgen.key > /var/run/jwtgen/jwt

# Refreshing loop
auto_refresh() {
    echo "Auto-refresh loop started. Interval: ${REFRESH_SLEEP}s"
    while true; do
        sleep $REFRESH_SLEEP
        /usr/local/bin/jwtgen-refresh.sh
    done
}

# Running in background
auto_refresh &

echo "JWT generator service is active. Monitoring logs..."
touch /var/log/jwtgen.log
tail -f /var/log/jwtgen.log