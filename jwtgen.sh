#!/usr/bin/env bash

# JWT Encoder - Optimized for Bash
HEADER_FILE=$1
PAYLOAD_FILE=$2
KEY_FILE=$3

# If env JWT_EXPIRE is empty, using default 3600s (1 hour) expiration time for the token
EXP_DELTA=${JWT_EXPIRE:-3600}

if [[ -z "$HEADER_FILE" || -z "$PAYLOAD_FILE" || -z "$KEY_FILE" ]]; then
    echo "Usage: $0 <header.json> <payload.json> <private.key>" >&2
    exit 1
fi

# Helper: Base64URL encoding
b64url() {
    base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

# Load and update payload with dynamic timestamps
# iat: now, exp: now + EXP_DELTA
HEADER=$(jq -c . "$HEADER_FILE" | tr -d '\n')
PAYLOAD=$(jq -c --arg iat "$(date +%s)" --arg delta "$EXP_DELTA" \
    '.iat=($iat|tonumber) | .exp=($iat|tonumber + ($delta|tonumber))' "$PAYLOAD_FILE")

# Encode segments
HEADER_B64=$(echo -n "$HEADER" | b64url)
PAYLOAD_B64=$(echo -n "$PAYLOAD" | b64url)

# Sign
SIGNATURE=$(echo -n "${HEADER_B64}.${PAYLOAD_B64}" | openssl dgst -sha256 -binary -sign "$KEY_FILE" | b64url)

# Output Token
echo "${HEADER_B64}.${PAYLOAD_B64}.${SIGNATURE}"