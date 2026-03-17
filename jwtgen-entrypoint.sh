#!/bin/bash
set -e # Exit on error

# Configuration
CERT_CONF="/tmp/cert.conf"
PRIV_KEY="/etc/ssl/private/jwtgen.key"
PUB_CERT="/etc/jwtgen/jwtgen.crt"
KID_FILE="/etc/jwtgen/kid"

# --- Key Persistence Logic ---
SHOULD_GENERATE=true

# Check if both key and cert exist
if [[ -f "$PRIV_KEY" && -f "$PUB_CERT" ]]; then
    echo "--- Existing key pair found. Checking validity... ---"
    
    # Verify if private key and certificate match using modulus comparison
    PUB_MODULUS=$(openssl x509 -noout -modulus -in "$PUB_CERT" | openssl md5)
    PRIV_MODULUS=$(openssl rsa -noout -modulus -in "$PRIV_KEY" | openssl md5)

    if [[ "$PUB_MODULUS" == "$PRIV_MODULUS" ]]; then
        echo "--- Existing key pair is valid. Skipping generation. ---"
        SHOULD_GENERATE=false
    else
        echo "--- Existing key pair is invalid or mismatched. Re-generating... ---"
    fi
fi

if [ "$SHOULD_GENERATE" = true ]; then
    echo "--- Generating RSA Key Pair ---"
    # Create temporary OpenSSL config for CSR
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
    # Generate 4096-bit RSA private key and a self-signed certificate
    openssl genrsa -out "$PRIV_KEY" 4096
    openssl req -new -x509 -days 3650 -key "$PRIV_KEY" -out "$PUB_CERT" -config "$CERT_CONF"
    
    rm -f $CERT_CONF
    chmod 600 "$PRIV_KEY"
fi
# --- End Key Persistence Logic ---

#Copy public cert to trusted location for jwtgen to use
cp $PUB_CERT /etc/ssl/certs/

# Generate Kid from PUB_CERT
KID=$(cat $PUB_CERT | sha1sum | awk '{print $1}')
echo -n "$KID" > "$KID_FILE"

# Update Header template with current KID
jq ".kid=\"$KID\"" /etc/jwtgen/jwt_header.json > /tmp/header.tmp && mv /tmp/header.tmp /etc/jwtgen/jwt_header.json

# Convert public certificate to JWKS format
/usr/local/bin/pem2jwks.py "$PUB_CERT" "$KID" > /etc/jwtgen/jwt.pub

echo "------------------------------------"
echo "JWT Public Key (JWKS):"
cat /etc/jwtgen/jwt.pub
echo "------------------------------------"

# Get expiration delta from environment (default to 1 hour)
EXP_DELTA=${JWT_EXPIRE:-3600}

# Calculate refresh interval (90% of the expiration duration)
REFRESH_SLEEP=$(( EXP_DELTA * 90 / 100 ))

echo "Generating initial JWT (Expiration: ${EXP_DELTA}s)..."
/usr/local/bin/jwtgen.sh /etc/jwtgen/jwt_header.json /etc/jwtgen/jwt_payload.json "$PRIV_KEY" > /var/run/jwtgen/jwt

# Function for background auto-refresh
auto_refresh() {
    echo "Auto-refresh thread started. Interval: ${REFRESH_SLEEP}s"
    while true; do
        sleep "$REFRESH_SLEEP"
        /usr/local/bin/jwtgen-refresh.sh
    done
}

# Run the refresh loop in the background
auto_refresh &

echo "JWT generator service is active. Monitoring logs..."
tail -f /var/log/jwtgen.log