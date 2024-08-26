---
layout: page
title: Edge Window
description: null
image:
  path: http://example.jpg
  feature:
  credit:
  creditlink:
tags: [macbook, window]
comments: true
reading_time: true
modified: 2024-08-25
---



A few months ago, the screen of my MacBook Pro cracked. At the time, I placed the laptop next to the sofa, when I was too tired in that evening, I accidentally let the computer fall. When I picked it up, I noticed that the edge of the screen was damaged. The width was about 35 points, and the height extended from top to bottom, it’s completely black. This MacBook was produced in 2013, after checking again and again, I found that the cost of repairing the screen was not worth it at all, and the second-hand prices were quite outrageous. The key point is that Apple has abandoned supporting this model with the latest system just a couple of days ago, so the newest system can only support up to macOS 11, making it not worth repairing.

> During my search, I accidentally discovered the "headless MacBook" series, which make me curious. However, compared to the official edition, the price has dropped significantly, so I am now inclined not to repair it physically, after all, my device still has a head basically.



Although I don't use this computer much, there is a very annoying situation when I do use it. When I make a window full screen, due to the physical screen being partially damaged, but the operating system not recognizing it, a portion of the content becomes invisible. The most obvious effect is that the Apple logo in the top left corner is not visible. So every time I apply full screen mode, I need to manually adjust the window size to avoid being obscured by the damaged area. Having to manually adjust every time is a hassle, and I'd tried third-party software like Moom and searched on Google, but I hadn’t found a good solution.



So I decide to fix it softly by writing a program. With the help of GPT and my own experience, I quickly built a simple utility tool that does one thing: whenever a window on the screen is obscured by the damaged area, it immediately moves it to the right, preventing the damaged area from blocking other windows. I also made an extended screen adaptation, so when switching windows between the two screens, it only makes window corrections on the damaged screen. If a window is outside the normal display area, it will also be immediately corrected to the normal displayable range. I named this app "Edge Window".



Project: **[EdgeWindow](https://github.com/xingheng/edgewindow) **

![Edge Window Screenshot](/images/edge-window-configuration.png)



I can’t control over the menu bar at all, and I can't fully control the Dock either. Previously, I placed the Dock on the left side, but now I can only place it on the right side, with the aim of displaying as many effective elements within the usable range as possible. 



Additionally, the core of `EdgeWindow` is to control the windows of other processes through the Application Service. This process, whether traversing or resizing windows, is very slow in execution. I even suspect that its underlying implementation is through apple script. The memory consumption is acceptable, but during window operations, the CPU usage hovers around 15% which is unacceptable for me. Therefore, I initially intended to have it automatically listen for all window movements, but I decided against it, as I do not want such a small tool to consume too many system resources. Now, in idle state, the CPU usage is below 1%, and the memory is around 15MB.
