#!/bin/bash

# Generating key pair
cat <<EOF > /tmp/cert-tmp.conf
[req]
distinguished_name = HUYDO-LAB
req_extensions = v3_req
prompt = no
[HUYDO-LAB]
C = VN
ST = Hanoi
L = Hanoi
O = huydo.net
OU = cybr
CN = HUYDO-LAB
[v3_req]
EOF

openssl genrsa -aes256 -passout pass:changeme -out /etc/ssl/private/jwtgen.pass.key 4096
openssl rsa -passin pass:changeme -in /etc/ssl/private/jwtgen.pass.key -out /etc/ssl/private/jwtgen.key
openssl req -new -x509 -days 3650 -key /etc/ssl/private/jwtgen.key -out /etc/ssl/certs/jwtgen.crt -config /tmp/cert-tmp.conf
rm /tmp/cert-tmp.conf
chmod -R 600 /etc/ssl/private

# Generating Kid from hostname
kid=$(hostname | sha1sum | awk '{print $1}')
echo -n $kid >/etc/jwtgen/kid
jq ".kid=\"$kid\"" /etc/jwtgen/jwt_header.json > /tmp/jwt_header.json
mv /tmp/jwt_header.json /etc/jwtgen/jwt_header.json

# Converting public cert to jwks format
/usr/local/bin/pem2jwks.py /etc/ssl/certs/jwtgen.crt $kid > /etc/jwtgen/jwt.pub

echo "$(date) Starting jwtgen container ..."
echo "===================================="
echo "JWT Public key:"
cat /etc/jwtgen/jwt.pub
echo "===================================="

# Creating jwt for first time
echo -n "Generating first jwt ... "
/usr/local/bin/jwtgen.sh \
    /etc/jwtgen/jwt_header.json \
    /etc/jwtgen/jwt_payload.json \
    /etc/ssl/private/jwtgen.key > /var/run/jwtgen/jwt
[[ $? -eq 0 ]] && echo " done"  || echo " failed"

echo -n "Starting cron service ... "
crontab /etc/cron.d/jwtgen.cron
cron
[[ $? -eq 0 ]] && echo " done"  || echo " failed"

# Preparing log file
echo "$(date) Starting new log data ..." > /var/log/jwtgen.log
tail -f /var/log/jwtgen.log


