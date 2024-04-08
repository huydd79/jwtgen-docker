# jwtgen-docker - Template for container to create secure jwt for authentication
Docker template for creating and managing jwt for authentication purpose

Any comments, please send to huy.do@cyberark.com

# Explaination
- Key pair is created when the container start
+ Private key is secured in container environment /etc/ssl/private which allow access for root permission only
+ Public key is converted to jwks and is shared out over docker logs and file: /etc/jwtgen/jwt.pub
- jwt is created with the content from json template
+ jwt's kid information is generated using sha1sum of container's hostname
+ jwtgen-refresh.sh is run using cron job, refreshing jwt content every 5 minutes

# Testing
- Build the container image using 01.build.sh script
- Run image using 02.test.sh script; copy public jwks content
- Getting jwt using 03.show-jwt.sh; copy the content of jwt
- Going to jwt.io, pasted the jwt content and jwks into webpage to verify the jwt value

  
