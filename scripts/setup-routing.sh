#!/bin/bash
# The "Plumbing" script to connect the containers
echo "Applying NAT and Forwarding rules..."

# Enable forwarding and NAT on Router
podman exec -it virtual_router sysctl -w net.ipv4.ip_forward=1
podman exec -it virtual_router iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

# Enable NAT on Gateway
podman exec -it gateway_proxy sysctl -w net.ipv4.ip_forward=1
podman exec -it gateway_proxy iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o eth1 -j MASQUERADE

# Fix Client PC Routing (Assuming Router is at 10.89.4.3)
podman exec --privileged -it client_pc ip route del default
podman exec --privileged -it client_pc ip route add 10.89.4.0/24 dev eth0
podman exec --privileged -it client_pc ip route add default via 10.89.4.3

echo "Network Path Established."
