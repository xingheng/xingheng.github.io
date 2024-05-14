---
layout: page
title: How to determine the macOS app via an unknown window
description: null
image:
  path: http://example.jpg
  feature:
  credit:
  creditlink:
tags: [macOS, Inspector, AppleScript]
comments: true
reading_time: true
modified: 2024-05-14
---



## Background

最近我的 mac 上有一个功能让我特别烦，因为我经常在 Chrome 里用 crxMouse 这个插件，所以习惯了在窗口里通过划 L 来关闭窗口等等，但是不知道什么时候开始，这个功能也在 macOS native apps 里面生效了。本来看起来是挺好的，但是可能是因为不兼容新系统的原因，这个未知的 app 在触发手势的时候总是画出一个不透明的窗口，大小 800x800，实在是丑爆了。

我怎么都想不起来这是什么 app 开启的，是什么时候开启的。因为之前很长一段时间里我都是只用 TrackPad 的，只是最近开始用普通鼠标的，而它是通过按住鼠标右键划线开始触发的。

![jitouch-gesture-window](/images/jitouch-gesture-window.png)



## Inspector

每当这个时候我都是第一时间想到用 `Accessibility Inspector.app` 来救场，比如前两个月我碰到过几次因为 Force Quit 弹出的进程恢复窗口不能关闭的问题。直接启动 Inspector.app，然后锚定那个弹窗，马上就能找到具体是哪个进程的弹窗了，然后马上 `killall UserNotificationCenter`，生效。

> 这个问题其实很多人之前都遇到过，[usernotificationcenter freezing constantly](https://discussions.apple.com/thread/7289428)。



![force-quit-alert](/images/force-quit-alert.png)

但是这次的这个手势 window 确不能直接用这种方法，它实在太难捕获了。在通过鼠标右键划线激活它的时候，我没办法再切换 app 到 Inspector.app 里点击选中锚定元素，因为鼠标被占用了。而键盘快捷键呢？ `Enable Point to Inspect` 的快捷键是`⌃⌥⇧⌘P`，没错，它需要我五根手指，而且还不都在一起。手实在是不够用…



## AppleScript

真的不行就用假的来凑，我想到用 applescript 来模拟点击触发。上一次正经写 applescript 的时候已经是好几年前了，那个时候 GPT 还没有这么热，这次终于能快速辅助我解决问题了。GPT 也就适合干这种基础简单的工作了。

```
-- Prepare to activate the unknown window
delay 3

-- Activate the Accessibility Inspector app
tell application "Accessibility Inspector" to activate

-- Click the "Inspection" menu and select "Enable Point to Inspect"
tell application "System Events"
  tell process "Accessibility Inspector"
    click menu item "Enable Point to Inspect" of menu "Inspection" of menu bar 1
    click
  end tell
end tell
```

扔到 Script Editor 里直接点击运行，然后马上手动触发手势 window，3 秒延迟过后，Inspector 马上抓取到了 View Hierarchy，结果居然是 `Jitouch`，这个结果是我万万没想到的。马上去 Jitouch app 里找到可疑开关，在关闭 *Enable Character Recognition for `Mouse`* 之后，窗口终于消失了，验证成功。

![Screen Shot 2024-05-14 at 10.59.12 PM](/images/jitouch-gesture-window-view-hierarchy.png)

#### Update

意外发现在启动 Accessibility Inspector 之后，还可以通过全局快捷键 `Alt + Space` 来快速锚点和锁定 view element，这下可就容易触发多了，相当于在这个快捷键的作用下也可以不需要上面的 AppleScript 来辅助锚定 Jitouch window 了。



## Conclusion

这篇文章主要介绍了 Xcode 内置工具 Accessibility Inspector.app 的强大用途，同时结合简单的 AppleScript 来模拟键盘鼠标的交互可以在 macOS 里实现快速的页面元素定位。Inspector 这个工具在十多年前我第一次用 mac 的时候就接触到了，当时是跟测试工程师那里学到的，它可以协助开发工程师完成 Accessibility 相关的功能开发，比如盲人可以使用的 VoiceOver 功能。

