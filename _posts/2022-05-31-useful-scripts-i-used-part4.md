---
layout: page
title: Useful scripts I used (Part 4)
description: 我用过的有用的脚本(4)
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink:
tags: [script, shell, bash, macOS]
comments: true
reading_time: true
modified: 2022-05-31
---



> Simple WLAN network diagnosing.



#### WLAN

偶尔我需要检查我的设备到路由器之间的网络状态：

```bash
# Check current router's packet.
check-router:
    #!/usr/bin/env bash
    set -euo pipefail
    
    route_ip=$(netstat -nr | grep -E "default.*en0" | awk '{ print $2 }')
    traceroute -q 5 ${route_ip} 100
```

甚至扫描当前局域网的其他设备网络情况：

```bash
# Scan current subnet's port and system info.
check-subnet:
    #!/usr/bin/env bash
    set -euo pipefail
    
    route_ip=$(netstat -nr | grep -E "default.*en0" | awk '{ print $2 }')
    # nmap ${route_ip}

    echo "TCP/IP fingerprinting (for OS scan) requires root privileges."
    sudo nmap -T5 -O --osscan-guess ${route_ip}/24 | tee nmap-subnet-scan-$(date +%s).log
```



和之前其他的脚本不同，这种不那么频繁的操作我不会放在我的`.zshrc` 里面，而是单独放在一个我常用的工作目录，通过 [just(file)](https://github.com/casey/just)  来管理。



#### Example

执行起来就比较方便了，直接：

```bash
just check-router
just check-subnet
```

