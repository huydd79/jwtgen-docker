#!/bin/bash
echo "Current JWT Token:"
docker exec jwtgen cat /var/run/jwtgen/jwt
echo -e "\n"