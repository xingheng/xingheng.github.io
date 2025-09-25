---
layout: page
title: CLI alarm clock.
description: 我用过的有用的脚本(6)
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



> Sir, you should wake up lightly.



#### Alarm

前段时间在公司的时候午休时间我一般会小憩一会儿，但是很容易睡过头了，睡久了下午反而更没精神了，所以我需要这样一个办公室闹钟：不会打扰其他人，只会叫醒我自己，更不要瞎吵吵一下子把我吓醒的。

通常很多音频播放类 app 都会有延时停止的功能，但是延时播放的倒计时闹钟好像并不多，于是索性自己写一个。

```bash
# Play music after specified duration as an alarm.
alarm:
    #!/usr/bin/env bash
    set -euo pipefail

    echo -n "How soon should I wake you up? > "
    read num

    duration=$(expr 60 \* $num)
    echo "$(date +%H:%M:%S): Sleeping $num minute(s)..."
    sleep $duration
    echo "$(date +%H:%M:%S): Time to wake up..."

    list="
    /Users/hanwei/Music/网易云音乐/Hans Zimmer - First Step.mp3
    /Users/hanwei/Music/网易云音乐/Hans Zimmer - Flying Drone.mp3
    /Users/hanwei/Music/网易云音乐/Hans Zimmer - Cornfield Chase.mp3
    /Users/hanwei/Music/网易云音乐/Hans Zimmer - No Time For Caution.mp3
    /Users/hanwei/Music/网易云音乐/Hans Zimmer - S.T.A.Y.mp3
    /Users/hanwei/Music/Download/安室奈美惠-FIGHT TOGETHER.mp3
    /Users/hanwei/Music/Download/高梨康治 - 出陣.mp3
    "

    IFS=$'\n' array=($list)

    trap "say \"Welcome back, sir! \" &" SIGINT SIGTERM SIGQUIT

    while true
    do
        for element in "${array[@]}"
        do
            echo "Playing $(tput setaf 2)$(basename $element)$(tput sgr 0)"
            afplay -v 0.3 -q 1 $element
        done
    done
```

我大爱 *星际穿越* 里面 `Hans Zimmer` 的配乐，所以选了几首轻的音乐当开头，最后两个分别是 One Piece 和 Naruto 里面的主题曲和背景音乐，相对亢奋。通常两个大循环就能把我叫醒了。



#### Example

```bash
just alarm
```
