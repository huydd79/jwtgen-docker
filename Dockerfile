FROM debian

LABEL maintainer="Huy Do <huy.do@cyberark.com>"
LABEL description="Container with jwtgen for conjur authentication"

RUN apt-get update && \
    apt-get install -y jq openssl cron python3 python3-jose && \
    mkdir -p /etc/jwtgen /etc/ssl/private /var/run/jwtgen 

COPY jwtgen.sh jwtgen-refresh.sh jwtgen-entrypoint.sh pem2jwks.py /usr/local/bin/
COPY jwtgen.cron /etc/cron.d/
COPY jwt_header.json jwt_payload.json /etc/jwtgen/

RUN chmod +x /usr/local/bin/* 

#ENTRYPOINT [ "/bin/bash" ]
#CMD (cron -f &) && tail -f /var/log/jwtgen.log
ENTRYPOINT [ "/usr/local/bin/jwtgen-entrypoint.sh" ]