#!/bin/bash
echo "Current JWT Token:"
docker exec hdo-jwtgen cat /var/run/jwtgen/jwt
echo -e "\n"