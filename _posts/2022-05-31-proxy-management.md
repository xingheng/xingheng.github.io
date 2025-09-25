---
layout: page
title: Proxy management
description: 我用过的有用的脚本(3)
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink:
tags: [script, shell, bash, macOS, proxy]
comments: true
reading_time: true
modified: 2022-05-31
---



> Manage the all kinds of proxies.



#### Proxy

* 控制/查看 curl 相关的工具代理
* 控制/查看 git 的代理环境
* 控制/查看 npm 的代理环境
* 控制/查看 macOS 系统代理设置

这个 function 一直同步更新到了[这里](https://gist.github.com/xingheng/c43933c88e8714275cfb415bf46c9e64)。

```bash
function proxy() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -p | --port)
        PORT="$2"
        shift # past argument
        shift # past value
        ;;
      --all)
        CORE_ENABLED=true
        GIT_ENABLED=true
        NPM_ENABLED=true
        SYSTEM_ENABLED=true
        shift
        ;;
      --core)
        CORE_ENABLED=true
        shift
        ;;
      --git)
        GIT_ENABLED=true
        shift
        ;;
      --npm)
        NPM_ENABLED=true
        shift
        ;;
      --system)
        SYSTEM_ENABLED=true
        shift
        ;;
      -s | --netservice)
        NETWORK_SERVICE="$2"
        shift # past argument
        shift # past value
        ;;
      -h | --help | help)
        echo "proxy [on|off|list] [--all] [--core] [--git] [--npm] [--system] [-h|--help|help] [-p|--port NUM] [-s|--netservice SERVICE]"
        return 0
        ;;
      on | off | list)
        ACTION="$1"
        shift
        ;;
      *)
        echo "Unknown argument: $1"
        return 1
        ;;
    esac
  done

  PORT=${PORT:-1087}
  NETWORK_SERVICE=${NETWORK_SERVICE:-Wi-Fi}
  ACTION=${ACTION:-list}

  [[ $GIT_ENABLED != true ]] && [[ $NPM_ENABLED != true ]] && [[ $SYSTEM_ENABLED != true ]] && CORE_ENABLED=true

  case ${ACTION} in
    on)
      if [[ $CORE_ENABLED == true ]]; then
        export HTTP_PROXY="http://127.0.0.1:$PORT"
        export HTTPS_PROXY=$HTTP_PROXY
        export http_proxy=$HTTP_PROXY
        export https_proxy=$HTTP_PROXY
        export FTP_PROXY=$HTTP_PROXY
        export SOCKS_PROXY=$HTTP_PROXY

        export NO_PROXY="localhost,127.0.0.1,::1"

        env | grep -e _PROXY -e _proxy | sort
        echo -e "Proxy-related environment variables set."
      fi

      if [[ $GIT_ENABLED == true ]]; then
        export GIT_CURL_VERBOSE=true
        export GIT_TRACE=true
        export GIT_TRACE_PACKET=true
        export GIT_SSL_NO_VERIFY=true

        # git config --global http.proxy "$HTTP_PROXY"
        # git config --global http.sslVerify false
        # git config --global http.sslcainfo /bin/curl-ca-bundle.crt
        # git config --system http.sslcainfo /bin/curl-ca-bundle.crt

        env | grep -e GIT_ | sort
        echo -e "Proxy-related environment variables set."
      fi

      if [[ $NPM_ENABLED == true ]]; then
        npm config set proxy "$HTTP_PROXY"
        npm config set https-proxy "$HTTP_PROXY"
        npm config set strict-ssl false
        npm config set registry "http://registry.npmjs.org/"
      fi

      if [[ $SYSTEM_ENABLED == true ]]; then
        networksetup -setwebproxy "$NETWORK_SERVICE" 127.0.0.1 "$PORT" off
        networksetup -setwebproxystate "$NETWORK_SERVICE" on
        networksetup -setsecurewebproxy "$NETWORK_SERVICE" 127.0.0.1 "$PORT" off
        networksetup -setsecurewebproxystate "$NETWORK_SERVICE" on
      fi
      ;;

    off)
      if [[ $CORE_ENABLED == true ]]; then
        unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy FTP_PROXY SOCKS_PROXY NO_PROXY

        env | grep -e _PROXY -e _proxy | sort
        echo -e "Proxy-related environment variables removed."
      fi

      if [[ $GIT_ENABLED == true ]]; then
        unset GIT_CURL_VERBOSE GIT_TRACE GIT_TRACE_PACKET GIT_SSL_NO_VERIFY

        # git config --global --unset http.proxy
        # git config --global --unset http.sslVerify
        # git config --global --unset http.sslcainfo
        # git config --system --unset http.sslcainfo

        env | grep -e GIT_ | sort
        echo -e "Proxy-related environment variables removed."
      fi

      if [[ $NPM_ENABLED == true ]]; then
        npm config delete proxy
        npm config delete https-proxy
        npm config delete strict-ssl
        npm config delete registry
      fi

      if [[ $SYSTEM_ENABLED == true ]]; then
        networksetup -setwebproxy "$NETWORK_SERVICE" "" "" off
        networksetup -setwebproxystate "$NETWORK_SERVICE" off
        networksetup -setsecurewebproxy "$NETWORK_SERVICE" "" "" off
        networksetup -setsecurewebproxystate "$NETWORK_SERVICE" off
      fi
      ;;

    list)
      if [[ $CORE_ENABLED == true ]]; then
        echo -e "Proxy-related environment variables' value:"
        env | grep -e _PROXY -e _proxy -e GIT_ | sort
      fi

      if [[ $GIT_ENABLED == true ]]; then
        printf "Git global proxy:"
        printf "%s" "$(git config --global --get http.proxy)"
        printf "%s" "$(git config --global --get http.sslVerify)"
        printf "\n"
      fi

      if [[ $NPM_ENABLED == true ]]; then
        printf "npm proxy:\n"
        printf "proxy: %s\n" "$(npm config get proxy)"
        printf "https-proxy: %s\n" "$(npm config get https-proxy)"
        printf "strict-ssl: %s\n" "$(npm config get strict-ssl)"
        printf "registry: %s\n" "$(npm config get registry)"
      fi

      if [[ $SYSTEM_ENABLED == true ]]; then
        printf "System global proxy (http):\n"
        printf "%s" "$(networksetup -getwebproxy "$NETWORK_SERVICE")"
        printf "System global proxy (https):\n"
        printf "%s" "$(networksetup -getsecurewebproxy "$NETWORK_SERVICE")"
      fi
      ;;

    *)
      echo -n "available actions: on, off, list"
      return 1
      ;;
  esac
}
```



#### Example

在当前 terminal session 里开启/关闭代理：

```bash
proxy on|off|list
```

```bash
proxy on [--port 7890]
```

> 通过修改常见的 `HTTP_PROXY` `HTTPS_PROXY` `http_proxy` `https_proxy` `FTP_PROXY` `SOCKS_PROXY` 环境变量改变后续的脚本网络代理。
>
> 默认使用 socks 1080 端口。

修改/查看 git 相关的环境变量：

```bash
proxy on|off|list --git
```

修改/查看 npm 相关的环境变量：

```bash
proxy on|off|list --npm
```

修改/查看 (macOS) 系统指定网口的代理设置：

```bash
proxy on|off|list --system
```

```bash
proxy on --system --netservice Wi-Fi --port 7890
```

查看用法：

```bash
proxy --help
```
