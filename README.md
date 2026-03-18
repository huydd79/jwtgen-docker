# jwtgen-docker - Template for container to create secure jwt for authentication
Docker template for creating and managing jwt for authentication purpose

Any comments, please send to huy.do@cyberark.com

# Explaination
- Key pair is created when the container start if they are not existed
  - Key pair are stored in /etc/jwtgen/keypair/jwt-prv.key and jwt-pub.key. If you want to reuse, don't delete them
  - If you have your own key pair, copy them to data folder and mapping to container when starting.
  - Private key shoud be secured in container environment which allow access for root permission only
  - Public key is converted to jwks and is shared out over docker logs and file: /etc/jwtgen/jwt.pub
  - KID is calculated base on public key
- jwt is created with the content from json template
  - jwt's kid information is generated using sha1sum of public key
  - jwt expire time is set base on JWT_EXPIRE environment variable, default is 3600 secs (1 hour)
  - jwtgen-refresh.sh is run in background after sleeptime=90% of JWT_EXPIRE


# Testing
- Build the container image using 01.build.sh script
- Run image using 02.test.sh script; copy public jwks content
- Getting jwt using 03.show-jwt.sh; copy the content of jwt
- Going to jwt.io, pasted the jwt content and jwks into webpage to verify the jwt value

  
