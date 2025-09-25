---
layout: page
title: VPN Client in Docker for macOS
description: null
image:
  path: http://example.jpg
  feature:
  credit:
  creditlink:
tags: [vpn, docker, macOS]
comments: true
reading_time: true
modified: 2024-12-20
---



## Background

This is the second time that I have to run VPN (AnyConnect) client in docker on macOS to solve the network issue, then some mates think it’s odd. However, I think it’s a more elegant solution to control the network traffic instead of routing table.

> In macOS, a VPN client operates by creating a virtual network interface that encapsulates traffic intended for secure transmission over the internet. The routing of this traffic is managed through modifications in the system's routing table, directing packets through this virtual adapter while utilizing underlying physical interfaces for actual data transmission.

The routing table is designed as IP address based, conflicts may happen when multiple VPN clients are running. In most cases, I prefer to route the traffic through the server domain name and/or process name.



## Docker Image

```bash
docker run --privileged \
  --name openconnect \
  --platform linux/amd64 \
  -d \
  -p 127.0.0.1:9000:9000 \
  -p 127.0.0.1:8123:8123 \
  -p 127.0.0.1:53:53/tcp \
  -p 127.0.0.1:53:53/udp \
  -v custom.conf:/etc/unbound/unbound.conf.d/custom.conf \
  -e OPTIONS="-u $USERNAME --servercert $CERTIFICATE" \
  -e SERVER="$VPN_SERVER" \
  -e PASSWORD="$MYPASS" \
  -e HTTP_PROXY_USERNAME="" \
  -e HTTP_PROXY_PASSWORD="" \
  -t gibby/openconnect
```

`gibby/openconnect` is the docker image I used in the first time, a few years passed, I found it's still working but not maintained. Here is the hub of the image: [gibby/openconnect](https://hub.docker.com/r/gibby/openconnect), it guides to use 8123 as http proxy port and 9000 as socks proxy port.



## Clash

Clash is a proxy tool for macOS, it supports the socks5 proxy and http proxy.


```yaml
# Clash configuration file
# https://en.clash.wiki/configuration/configuration-reference.html

# Port of HTTP(S) proxy server on the local end
port: 7890

# Port of SOCKS5 proxy server on the local end
socks-port: 7891

# HTTP(S) and SOCKS4(A)/SOCKS5 server on the same port
mixed-port: 7890

# Clash router working mode
# rule: rule-based packet routing
# global: all packets will be forwarded to a single endpoint
# direct: directly forward the packets to the Internet
mode: rule

# Clash by default prints logs to STDOUT
# info / warning / error / debug / silent
log-level: info

# RESTful web API listening address
external-controller: 127.0.0.1:9090

dns:
  enable: true
  # listen: 0.0.0.0:53

  default-nameserver:
    - 8.8.8.8

  nameserver:
    - 8.8.8.8
    - tls://dns.google:853 # DNS over TLS
    - tls://1.0.0.1:853
    - https://1.1.1.1/dns-query # DNS over HTTPS
    - dhcp://en0 # DNS from dhcp

proxies:
  - name: vpn1
    type: http
    server: "127.0.0.1"
    port: 8123  # HTTP Port exposed from openconnect in docker
    username: ""
    password: ""

  - name: vpn2
    type: http
    server: "127.0.0.1"
    port: 8124  # HTTP Port exposed from openconnect in docker if exists
    username: ""
    password: ""

proxy-groups:
  - name: TEAM-VPN1
    type: select
    proxies:
      - vpn1

  - name: TEAM-VPN2
    type: select
    proxies:
      - vpn2

rules:
  - DOMAIN-SUFFIX,gitlab.compay.com,TEAM-VPN1
  - DOMAIN-SUFFIX,jekins.compay.com,TEAM-VPN2

  - SRC-IP-CIDR,192.168.1.1/24,DIRECT
  # optional param "no-resolve" for IP rules (GEOIP, IP-CIDR, IP-CIDR6)
  - IP-CIDR,127.0.0.0/8,DIRECT
  - GEOIP,CN,DIRECT
  - DST-PORT,80,DIRECT
  - SRC-PORT,7777,DIRECT
  - MATCH,DIRECT
```

Now, we can use two VPN services with custom domain and ip rules to route the traffic through the Clash network. 7890 is the default port of Clash, once it's set to the system network interface's proxy setting, all the processes will follow the proxy setting.

