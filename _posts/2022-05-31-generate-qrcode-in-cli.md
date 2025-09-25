---
layout: page
title: Generate qrcode in CLI
description: 我用过的有用的脚本(5)
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



> Show me the [qr]code.



#### QRCode

有时候我需要把一个 URL 链接在手机上打开，当 iCloud 跨设备剪贴板共享并不能满足我的需求的时候，我就会用到它：

```bash
# Generate & show qrcode based on current clipboard.
qrcode:
    #!/usr/bin/env bash
    set -euo pipefail

    content=$(pbpaste)

    if [[ -z $content ]]; then
        echo "No content found in clipboard, exit..."
        exit
    fi

    tmp_file=$(mktemp --suffix ".png")
    trap "rm -fr $tmp_file; echo Removed." SIGINT SIGTERM SIGQUIT EXIT

    qrencode -o $tmp_file $content -m 1
    echo $tmp_file
    open -g -W $tmp_file
    # bash $HOME/.iterm2/imgcat $tmp_file
```

`qrencode` 来源于[这里](https://fukuchi.org/works/qrencode/)，它的输出是一个二维码的图片文件，在我使用完了之后我会通过 ctrl+c 的方式杀掉它并自动清除这个临时文件。



#### Example

1. 复制 URL 到剪贴板
2. 在对应的 [justfile]所在目录里执行 `just qrcode`
3. 使用手机扫码
4. Ctrl + c 结束使用
