## A Note to the Future Me (And the Stranded Traveler)

**Date:** January 31, 2026
**Subject:** The Day the Nokia Router Failed, and the Gateway was Born.

If you are reading this, future David, you are likely staring at a locked-down ISP router or a client who needs "a somewhat wierd" networking. Or perhaps, traveler, you've stumbled upon this repo after hours of `iptables` errors and "Operation not permitted" loops, looking for a way to teleport your traffic through a trusted node.

I built this because the hardware I had wasn't enough. I needed a bridge built not on passwords, but on the cold, hard math of **Digital Certificates**.

### The Problem
A router that wouldn't talk. A network that needed to be centralized. A requirement for "Role-Based Access" where only the chosen (those with the certificate) could pass.

### The Solution
This repository is a **Software-Defined Regional Gateway**. It turns a simple Linux box into a Certificate Authority and a Traffic Hub. It uses Podman to containerize the chaos and OpenVPN to encrypt the journey.

### What’s Inside?
- **`compose.yml`**: The blueprint of the three-node simulation.
- **`manual.md`**: The "World-Class" guide on how to reproduce this on real hardware.
- **`scripts/`**: The automation to keep you from typing `ip route` until your fingers bleed.

### How to Use This
If you're in a hurry, run the scripts in `scripts/` in order. If you want to understand the "Why," read the `manual.md`.

*To the future me: Don't forget to load the kernel modules on the host. Arch won't do it for you. Stay curious. Build the bridge.* **— d3fault**
