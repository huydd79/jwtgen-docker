#!/usr/bin/python3
import sys
import json
from jose import jwk

def generate_jwks(cert_path, kid):
    try:
        with open(cert_path, 'rb') as f:
            cert_data = f.read()
        
        # Use jose library to construct the JWK from the public cert
        key = jwk.RSAKey(algorithm='RS256', key=cert_data.decode('utf-8'))
        jwks_dict = key.to_dict()
        
        jwks_dict.update({
            "kid": kid,
            "use": "sig",
            "alg": "RS256"
        })
        
        return json.dumps(jwks_dict, indent=4)
    except Exception as e:
        return f"Error: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <cert_file> <kid>")
        sys.exit(1)
    
    print(generate_jwks(sys.argv[1], sys.argv[2]))