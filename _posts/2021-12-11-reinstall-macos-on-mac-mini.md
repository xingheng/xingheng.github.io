---
layout: page
title: Reinstall macOS Mojave on mac mini
description: 记一次 mac mini 重装系统.
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink:
tags: [mac-mini, macOS, OSX, EI-Capitan, Mojave, rsync]
comments: true
reading_time: true
modified: 2021-12-11
---



> Goodbye, EI Capitan.



#### 意外

找电工过来排查一个电暖灯的问题，中途给我整了两次连续停电，人走了后发现电脑怎么都开不了机。🙃🙃🙃

启动进度条只要走到中途一半就不走了，然后自动关机。重启进入 Recovery 模式，尝试硬盘修复，修复失败（没留存具体错误信息）。重启进入安全模式，磁盘只能挂载(mount)到只读模式，看不出来具体问题，`fsck` 也修复失败。

6年了，这个 OS X EI Capitan 终归是这么意外地走了，准备重装系统。



#### 备份数据

重启到安全模式，尝试挂载我的一块西数移动硬盘，结果怎么都不成功，不知道原因。重启到 Recovery 模式，在 Disk Utility 里面也挂载不了。一时间也没什么好办法，只好通过网络走 `rsync` 备份了。在安全模式下是无法连接网络的，但是可以直接读源系统分区的内容。在 Recovery 模式下可以联网但是原系统分区没有自动挂载上，只好手动挂载了，主要通过 `diskutil` 实现：

```
diskutil list
diskutil info /dev/diskXsY
diskutil mount /dev/diskXsY
```

> References: [Mount & Unmount Drives from the Command Line in Mac OS X](https://osxdaily.com/2013/05/13/mount-unmount-drives-from-the-command-line-in-mac-os-x/)

准备把原系统下所有的数据备份，首选 `rsync`，但是它不是 OSX 系统自带的，Base System 里面根本就没有这个东西，只好尝试去原 EI Capitan 系统里面找，因为一些历史原因，之前我在那个系统里面把 `Homebrew` 的环境整坏了，但是 `rsync` 可能还是存在的，就是不知道在什么路径下面，在  `/usr` 目录下遍历了很久终于找到了，虽然这个系统分区不可写，但是执行还是没有问题的。

优先备份用户目录下的数据：

```
rsync -avr --progress /Volumes/MacOS/Users/Will 192.168.1.5:/Volumes/Elements/mac-mini/
```

因为数据量大概有600G的原因，这个过程本来预想的就会很长，但是另一个坑又来了，Base System  不知道为什么会有30分钟后自动休眠的设定，即使 shell 里有正在执行的任务。这导致我前一天晚上开始跑的 `rsync` 到第二天早上一看还是没有完，关键是一旦唤醒了就发现 `rsync` 在继续跑，因为 `rsync` 默认日志输出的原因，我看不到每一个文件的传输时间点。这一点儿让我迷惑了两个晚上，以为就是零碎文件太多导致读写时间太长，第三个晚上，我尝试输出 `rsync` 的时间日志，看看到底是什么原因为什么这么慢：

```
--out-format="%t %f %b"
```

> Refer to [here](https://serverfault.com/a/466107/220191).

最终发现是上面提到的自动休眠的原因造成的，关键是这个设定在 Base System 里面还没法儿改，这是为什么突然放弃 `rsync` 备份的其中一个原因，另一个原因是因为 `rsync` 在建立 ssh 连接的时候需要手动确认，因为 Base System 本身也是只读的，所以即使已经确认的 ssh host 也无法保存在当前系统配置里。这就意味着中途只要 `ssh` 连接中断一次，我就得重跑 `rsync`。

还是得回去解决为什么移动硬盘无法在 Base System 里面挂载的原因。



#### APFS

换了另一块 Time Machine 专用老硬盘发现居然可以挂载上，同样是西数的硬盘，对比了一下发现磁盘格式不一样。想起以前的这个老硬盘是用的 HFS 格式的文件系统，但是新的硬盘在开始使用的时候我都是直接格式化成 APFS 文件系统。因为当时考虑到家里除了这台 mac mini 之外，家里和公司的 macbook 都是新系统支持 APFS 的，APFS 确实在新系统下比 HFS 更好用。

这块 Time Machine 专用硬盘容量太小，只好把新硬盘里已有的数据转移到老硬盘里和 Time Machine 备份数据共存（不知道这会不会影响 Time Machine 的恢复），然后把新硬盘也格式化成 HFS (Mac OS Extended)，终于在 Recovery 模式下可以识别出来了。

继续 `rsync`，三个多小时就传完了。



#### 重装系统

因为 `Homebrew` 已经早早放弃了 EI Capitan 支持的原因，而且几个月前我把 openssl 的环境整坏了，索性下定决心重装换新系统了。配置新系统是一件很繁琐的事情，我并不太想从头开始。先试试从已有的 Time Machine 备份恢复一个试试看，上次备份的是一个10.15 Catalina macbook pro。

重启到 Recovery 模式开始恢复，恢复过程一切正常，但是重启进入系统还是进不去，进度条走得很慢，但是完全走完了还是卡在启动页很久，等一个多小时也无法进入登录页。有两个怀疑点：

1. Macbook 的备份无法恢复到 mac mini，但是这种概率比较小，因为以前我好想尝试过并且没有失败。
2. 前两天我转移数据到 Time Machine 的专用盘的时候把数据混淆了，数据不共存。

无法验证了，只好重装新系统了，现在已经无法从 Recovery 模式直接在线安装 Base System 对应的老系统了，所以我只好手动从官方渠道下载。

> [How to create a bootable installer for macOS - Apple Support](https://support.apple.com/en-us/HT201372)

1. 在 Macbook Big Sur 通过 AppStore 下载新的系统 [Mojave](https://apps.apple.com/us/app/macos-mojave/id1398502828?mt=12) 镜像。

   > 为什么选 Mojave？因为这个系统还算新，这个版本在我印象中还可以。

2. 找一个U盘准备写入系统镜像。

   ```
   sudo /Applications/Install\ macOS\ Mojave.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume
   ```

3. 按住 `Option` 键开机，进入引导系统后开始安装。

4. 选目标分区的时候发现无法选内置硬盘，Mojave 直接要求系统必须是 APFS，因为内置硬盘还是 HFS 格式的。重新退回 Disk Utility，格式化内置硬盘成 APFS 后继续安装。

5. 完成。

不得不说重装了新系统之后确实快了很多，这一点和 Windows 一样，有必要间隔几年重装一次，这个过程虽然折腾，但是一定程度上能解决一些累积出来的小问题。



#### Notes

老系统的镜像还是可以从官方渠道下载到的：

[OS X EI Capitan](http://updates-http.cdn-apple.com/2019/cert/061-41424-20191024-218af9ec-cf50-4516-9011-228c78eda3d2/InstallMacOSX.dmg)
但是往后的系统版本只能从 AppStore 安装。

