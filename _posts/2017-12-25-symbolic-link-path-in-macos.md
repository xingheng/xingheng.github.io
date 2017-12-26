---
layout: page
title: Symbolic link path in macOS
description: "Resolve the symbolic link path issue"
image:
  path: http://example.jpg
  feature: link_to_here.jpg
  credit: youtube
  creditlink: https://www.youtube.com/watch?v=eTyF1hVBsbo
tags: [mac, unix, shell]
comments: true
reading_time: true
modified: 2017-12-25
---



推荐阅读：[What Are Aliases, Symbolic Links, and Hard Links in Mac OS X?](https://www.lifewire.com/aliases-symbolic-links-hard-links-mac-2260189)

这篇对alias和symbolic link的区别解释得还是很全的，从应用层上看alias更针对普通用户的操作层，一次创建，随意移动，只有Finder能识别。对比了一下这两种文件的状态，发现主要区别还是alias只是一个普通二进制文件，Finder在创建alias的时候是完全创建了一个新的独立的文件，类型是`MacOS Alias file`。Finder的Get Info window中还可以对这种alias文件进行更改Original指向，也是对inode的直接修改，也难怪能够随意移动和创建alias及alias副本。只是不能在terminal里使用罢了。

尤其是针对目录的alias，这种文件在terminal几乎完全就是鸡肋。这个时候symbol link创建的目录快捷方式的就有优势多了，可以在`cd`之间来去自如，几乎就是一个真实存在的directory。

```shell
➜  ~ stat adir
  File: adir
  Size: 102       	Blocks: 0          IO Block: 4096   directory
Device: 1000003h/16777219d	Inode: 24269459    Links: 3
Access: (0755/drwxr-xr-x)  Uid: (  504/  will)   Gid: (   20/   staff)
➜  ~ stat adir_alias
  File: adir_alias
  Size: 868       	Blocks: 8          IO Block: 4096   regular file
Device: 1000003h/16777219d	Inode: 24269469    Links: 1
Access: (0644/-rw-r--r--)  Uid: (  504/  will)   Gid: (   20/   staff)
➜  ~ stat adir_symbol
  File: adir_symbol -> adir
  Size: 4         	Blocks: 8          IO Block: 4096   symbolic link
Device: 1000003h/16777219d	Inode: 24269465    Links: 1
Access: (0755/lrwxr-xr-x)  Uid: (  504/  will)   Gid: (   20/   staff)
➜  ~ 
```



symbol link directory作为快捷方式虽然方便，但是对于`pwd`/`$PWD`而言，有时候也会带来困扰。比如最近我发现`cmake`生成的`CMakeCache.txt`中就会记录cmake过程中的环境变量`$PWD`，这些变量就包含了很多逻辑目录路径(logical directory path)。

```shell
➜  ~ cd /path/to/adir
➜  ~ pwd
/path/to/adir
➜  ~ cd /path/to/adir_symbol
➜  ~ pwd
/path/to/adir_symbol
➜  ~ 
```

实际上adir和adir_symbol是指向一个目录的，但是对于pwd而言（默认）是两个不同的路径。要解决统一的物理目录路径（physical directory path）问题，可以用到`readlink`和`pwd -P`这两个命令。

```shell
➜  ~ cd /path/to/adir_symbol
➜  ~ pwd
/path/to/adir_symbol
➜  ~ pwd -P
/path/to/adir
➜  ~ readlink -f /path/to/adir_symbol
/path/to_adir
➜  ~ 
```

> readlink在GNU和mac下的行为稍有差异， 可以安装`coreutil`后用`greadlink`解决。

&nbsp;



相关阅读：

[Make Terminal Follow Aliases Like Symlinks](http://blog.warrenmoore.net/blog/2010/01/09/make-terminal-follow-aliases-like-symlinks/)

[How can I get the behavior of GNU's readlink -f on a Mac?](https://stackoverflow.com/questions/1055671/how-can-i-get-the-behavior-of-gnus-readlink-f-on-a-mac)



