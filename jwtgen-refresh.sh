#!/bin/bash
LOG="/var/log/jwtgen.log"

{
    echo -n "$(date) - Refreshing JWT..."
    /usr/local/bin/jwtgen.sh /etc/jwtgen/jwt_header.json /etc/jwtgen/jwt_payload.json /etc/ssl/private/jwtgen.key > /var/run/jwtgen/jwt
    echo " Done."
} >> "$LOG" 2>&1