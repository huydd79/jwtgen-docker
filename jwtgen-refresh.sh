#!/bin/bash
LOG="/var/log/jwtgen.log"
PRV_KEY="/etc/jwtgen/keypair/jwtget-prv.key"

{
    echo -n "$(date) - Refreshing JWT..."
    /usr/local/bin/jwtgen.sh /etc/jwtgen/jwt_header.json /etc/jwtgen/jwt_payload.json "$PRV_KEY" > /var/run/jwtgen/jwt
    echo " Done."
} >> "$LOG" 2>&1