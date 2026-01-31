#!/bin/bash
# Generate a certificate for a new router
CLIENT_NAME=$1
if [ -z "$CLIENT_NAME" ]; then
  echo "Usage: ./issue-cert.sh [client-name]"
  exit 1
fi

podman exec -it gateway_proxy easyrsa build-client-full "$CLIENT_NAME" nopass
podman exec -it gateway_proxy ovpn_getclient "$CLIENT_NAME" >"${CLIENT_NAME}.ovpn"
echo "Certificate generated: ${CLIENT_NAME}.ovpn"
