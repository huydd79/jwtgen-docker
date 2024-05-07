#!/bin/bash

LOG_FILE=/var/log/jwtgen.log

echo -n "$(date) Refreshing jwt value..." >> $LOG_FILE
/usr/local/bin/jwtgen.sh /etc/jwtgen/jwt_header.json /etc/jwtgen/jwt_payload.json /etc/ssl/private/jwtgen.key > /var/run/jwtgen/jwt
[[ $? -eq 0 ]] && echo " done" >> $LOG_FILE  || echo " failed" >> $LOG_FILE
