FROM debian:bookworm-slim

LABEL maintainer="Huy Do <huy.do@cyberark.com>"
LABEL description="Containerized JWT generator for Conjur authentication"

# Install dependencies and clean up cache to reduce image size
RUN apt-get update && \
    apt-get install -y jq openssl cron python3 python3-jose python3-cryptography && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /etc/jwtgen/keypair /var/run/jwtgen /var/log/jwtgen

COPY jwtgen.sh jwtgen-refresh.sh jwtgen-entrypoint.sh pubkey2jwks.py /usr/local/bin/
COPY jwt_header.json jwt_payload.json /etc/jwtgen/

RUN chmod +x /usr/local/bin/* && \
    touch /var/log/jwtgen.log

ENTRYPOINT [ "/usr/local/bin/jwtgen-entrypoint.sh" ]