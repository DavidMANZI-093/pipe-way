#!/bin/bash
# Initialize the Certificate Authority
echo "Initializing Gateway Configuration..."
podman run -v "$(pwd)/openvpn-data":/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://10.174.127.233
echo "Building the PKI. You will be asked for a Master Password. DO NOT FORGET IT."
podman run -v "$(pwd)/openvpn-data":/etc/openvpn -it --rm kylemanna/openvpn ovpn_initpki
