## The Gateway Protocol: Centralized VPN Deployment Manual

This manual outlines the process of building a Role-Based Access network using Digital Certificates to route traffic from a remote location (Location B) through a central exit node (Location A).

### 1. Prerequisites & Hosting Preparation (Arch Linux)

Before the containers can manage network traffic, your Linux kernel must be instructed to allow tunneling and NAT.

```bash
# Load necessary kernel modules
sudo modprobe tun
sudo modprobe iptable_nat
sudo modprobe ip_tables

# (Optional) Make them persistent across reboots
echo -e "tun\niptable_nat\nip_tables" | sudo tee /etc/modules-load.d/gateway.conf
```

### 2. The Infrastructure (`compose.yml`)

We use three distinct zones: the Gateway (Server), the Router (Identity Holder), and the Client (Consumer).

```yaml
services:
  # LOCATION A: The Trusted Exit
  gateway-proxy:
    image: kylemanna/openvpn
    container_name: gateway_proxy
    privileged: true
    volumes:
      - ./openvpn-data:/etc/openvpn
      - /lib/modules:/lib/modules:ro
    networks:
      external_net:
      internal_tunnel:
    cap_add:
      - NET_ADMIN

  # LOCATION B: The Client Router
  virtual-router:
    image: alpine
    container_name: virtual_router
    privileged: true
    tty: true
    networks:
      internal_tunnel:
      client_lan:
    command: /bin/sh -c "apk add --no-cache openvpn iptables iproute2 && tail -f /dev/null"

  # THE END USER: No configuration needed
  client-pc:
    image: alpine
    container_name: client_pc
    privileged: true
    networks:
      client_lan:
    command: /bin/sh -c "tail -f /dev/null"

networks:
  external_net:
    driver: bridge
  internal_tunnel:
    driver: bridge
  client_lan:
    driver: bridge
```

### 3. PKI: Generating the Digital Identity

Instead of passwords, we use Role-Based Access Control (RBAC) via certificates. The Gateway acts as the Certificate Authority (CA).

#### A. Initialize the CA (The "Root of Trust")

```bash
# 1. Create the base configuration
podman run -v $(pwd)/openvpn-data:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://YOUR_SERVER_IP

# 2. Build the CA (This creates your Master Private Key)
podman run -v $(pwd)/openvpn-data:/etc/openvpn -it --rm kylemanna/openvpn ovpn_initpki
```

#### B. Issue a Router Certificate

In a real-world scenario, you would do this for every router you deploy to a client.

```bash
# 3. Generate the client file (nopass allows the router to boot without human input)
podman exec -it gateway_proxy easyrsa build-client-full client-router-01 nopass

# 4. Export the .ovpn file (The Digital Certificate)
podman exec -it gateway_proxy ovpn_getclient client-router-01 > client-router-01.ovpn
```

### 4. Real-World Router Setup

In a physical deployment, the "Virtual Router" would be a device running OpenWrt or a dedicated VPN appliance.

**Physical Connection (How to "Get In")**

1. **Ethernet:** Plug your laptop into the **LAN port** of the router.
2. **Access:** Open a browser to `192.168.1.1` (usually).
3. **Upload:** Navigate to **VPN > OpenVPN Client** and upload the client `client-router-01.ovpn` file.
4. **Interface:** Ensure the router is set to "Route all traffic through tunnel."

**Virtual Simulation (TheSet-by-Step)**

```bash
# 1. Copy the cert to the router
podman cp client-router-01.ovpn virtual_router:/etc/openvpn/client.conf

# 2. Correct the 'remote' address to point to the gateway container
podman exec -it virtual_router sed -i 's/remote .*/remote gateway_proxy 1194/' /etc/openvpn/client.conf

# 3. Start the tunnel
podman exec -it virtual_router openvpn --config /etc/openvpn/client.conf &
```

### 5. Routing Logic: Turning a Container into a Gateway

A computer with a VPN is just a "connected computer." To make it a **Router**, it must perform **NAT (Network Address Translation)**.

**On The Virtual Router:**

```bash
# Enable Kernel Forwarding
podman exec -it virtual_router sysctl -w net.ipv4.ip_forward=1

# Masquerade (Hide the Client PC behind the tunnel IP)
podman exec -it virtual_router iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
podman exec -it virtual_router iptables -A FORWARD -i eth1 -o tun0 -j ACCEPT
```

**On the Gateway (Location A):**

```bash
# Allow the traffic to exit to the real internet
podman exec -it gateway_proxy iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o eth1 -j MASQUERADE
```

### 6. Platform-Specific Client Connection

If you weren't using a "Router" but connecting devices directly to Location A:

- **Linux (Arch/Ubuntu):** Install `openvpn` or `networkmanager-openvpn` and import the `.ovpn` file.
- **Windows:** Use the **OpenVPN Connect** official GUI. Right-click the icon > Import file.
- **macOS:** Use **Tunnelblick** or **Viscosity**. Drag and drop the `.ovpn` file into the app.

### 7. Cleanup & Teardown

To remove all traces of this simulation from your local machine:

```bash
# 1. Stop and remove containers/networks
podman compose down

# 2. Remove the certificate data
rm -rf ./openvpn-data ./client-router-01.ovpn

# 3. (Optional) Unload kernel modules
sudo modprobe -r tun iptable_nat ip_tables
```

**Troubleshooting the "Role-Based" Handshake**

If the tunnel won't start, check the logs: `podman logs gateway_proxy`

- **Common Error:** `TLS Error: cannot locate HMAC-SHA1 signature`.
- **Cause:** The clocks on the Router and Gateway are out of sync. Since certificates have a "Start Date," if your router thinks it is 1970, the certificate is "from the future" and invalid. Solution: Ensure NTP is enabled on all devices.
