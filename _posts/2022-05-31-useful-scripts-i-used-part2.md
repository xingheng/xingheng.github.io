---
layout: page
title: Useful scripts I used (Part 2)
description: 我用过的有用的脚本(2)
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



> Knock knock…



#### Notification

正准备跑一个时间可能很长的命令，然后切换到了其他 tab 或者 app 里去了，我想知道这个命令什么时候完成了才方便我再执行其他操作。

直接调用 macOS 内置的 `say` 通过语音的方式告诉结果：

```bash
# Notify me via TTS when the command is finished.
function @() {
    $@
    [[ $? -eq 0 ]] && say "Sir, $1 has been finished." || say "Sir, $1 has been failed."
}
```

并不是所有时间我都带着耳机或者电脑都开着外音，那就通过发送系统本地通知来告诉我好了：

```bash
# Show a system notification.
function notify() {
    local title="$1"
    local subtitle="$2"
    local content="$3"

    osascript -e "display notification \"${content}\" with title \"${title}\" subtitle \"${subtitle}\" sound name \"DEFAULT\""
}
```

本地通知一般是能被我看到的，但是有时候我就是忽略了，或者开启了勿扰模式，这个时候还是用 `alert` 弹窗的方式提醒自己好了：

```bash
# Show a system alert.
function alert() {
    local title="$1"
    local content="$2"

    osascript -e "display alert \"${title}\" message \"${content}\""
}
```

万一我离开了电脑怎么办，拿着手机出去吃饭了？那就通过 [Bark](https://apps.apple.com/us/app/bark-customed-notifications/id1403753865) 发一个远程推送通知到我的手机好了：

```bash
# Send notification via bark service.
function bark() {
    local app=$(urlencode "$(hostname)")
    local message=$(urlencode "$1")
    local request="https://api.day.app/--STRIPPED--/${app}/${message}"

    if command -v jq &> /dev/null; then
        local response=`curl -s ${request}`
        local code=`echo ${response} | jq -r ".code"`

        [[ $code -eq 200 ]] || echo "Send message failed: ${response}"
    else
        curl -s ${request} | grep "200"
        [[ $? -eq 0 ]] || echo "Send message failed!"
    fi
}
```

那如果我离开了电脑并且没带手机呢？

>  那肯定是在休息，还看个屁啊！



#### Example

```bash
@ wget https://foo.image
```

```bash
notify "wget" "finished downloding" "check details in terminal"
```

```bash
alert "wget" "finished downloding"
```

```bash
bark "wget finished"
```

