#!/bin/bash
set -e # Exit on error

# Configuration
CERT_CONF="/tmp/cert.conf"
PRV_KEY="/etc/jwtgen/keypair/jwtget-prv.key"
PUB_KEY="/etc/jwtgen/keypair/jwtget-pub.key"
KID_FILE="/etc/jwtgen/kid"

# --- Key Persistence Logic ---
SHOULD_GENERATE=true

# Check if both key and cert exist
if [[ -f "$PRV_KEY" && -f "$PUB_KEY" ]]; then
    echo "--- Existing key pair found. Checking validity. ---"
    
    PUB_MODULUS=$(openssl rsa -pubin -noout -modulus -in "$PUB_KEY" 2>/dev/null | openssl md5)
    PRIV_MODULUS=$(openssl rsa -noout -modulus -in "$PRV_KEY" 2>/dev/null | openssl md5)

    if [[ "$PUB_MODULUS" == "$PRIV_MODULUS" ]]; then
        echo "--- Existing key pair is valid. Skipping generation. ---"
        SHOULD_GENERATE=false
    else
        echo "--- Existing key pair is invalid or mismatched. Re-generating... ---"
    fi
fi

if [ "$SHOULD_GENERATE" = true ]; then
    echo "--- Generating RSA Key Pair ---"
    openssl genrsa -out $PRV_KEY 4096
    openssl rsa -in $PRV_KEY -pubout -out $PUB_KEY
    echo "--- Key pair created successfully. ---"
    chmod 600 "$PRV_KEY"
fi
# --- End Key Persistence Logic ---

# Generate Kid from PUB_KEY
KID=$(cat $PUB_KEY | sha1sum | awk '{print $1}')
echo -n "$KID" > "$KID_FILE"

# Update Header template with current KID
jq ".kid=\"$KID\"" /etc/jwtgen/jwt_header.json > /tmp/header.tmp && mv /tmp/header.tmp /etc/jwtgen/jwt_header.json

# Convert public certificate to JWKS format
/usr/local/bin/pubkey2jwks.py "$PUB_KEY" "$KID" > /etc/jwtgen/jwt.pub

echo "------------------------------------"
echo "JWT Public Key (JWKS):"
cat /etc/jwtgen/jwt.pub
echo "------------------------------------"

# Get expiration delta from environment (default to 1 hour)
EXP_DELTA=${JWT_EXPIRE:-3600}

# Calculate refresh interval (90% of the expiration duration)
REFRESH_SLEEP=$(( EXP_DELTA * 90 / 100 ))

echo "Generating initial JWT (Expiration: ${EXP_DELTA}s)..."
/usr/local/bin/jwtgen.sh /etc/jwtgen/jwt_header.json /etc/jwtgen/jwt_payload.json "$PRV_KEY" > /var/run/jwtgen/jwt

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