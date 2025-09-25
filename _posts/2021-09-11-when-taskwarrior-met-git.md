---
layout: page
title: When taskwarrior met git
description: How the use git repository to manage the taskwarrior data.
image:
  path: http://example.jpg
  feature: walle-eve-1.jpeg
  credit: Disney / Pixar
  creditlink:
tags: [taskwarrior, git, command-line, shell, software]
comments: true
reading_time: true
modified: 2021-09-11
---



> as wall-e met eve.



#### Story

Todo list 类的工具我用过很多了，印象中第一个在 Android 手机上用的是 [Any.do](https://www.any.do/)，早期还和 google calendar 做同步。后来换到了 iOS 生态就试着跟各种类似的软件打过交道了，同时期在桌面端也用过各种奇葩的方式，有存在线笔记的，teambition，trello，甚至最后用 git 仓库存 markdown 的，因为 markdown 支持一种 task list 的格式，而且在笔记中可以做到各种备注之类的。但是这种方式用太久就让我想不起来到底 todo list / item 的原本样貌到底是什么样的了，因为它完全没有章法。

工作和生活类的数据是完全分离的，在手机上后来我一直用的都是 iOS 自带的 Reminders，提醒功能是三方 app 服务不管怎么做都达不到原生级体验的。基本的任务属性也很明确，该有的都有，整体上我觉得中规中矩。

iCloud 的同步服务时好时外，一旦碰上它抽风了我就要问候苹果全家了，尤其是 mac 版的 Reminders。再加上那傻瓜式的 GUI 每次我都得在那个小窗口里面用鼠标点来点去才能完成一个任务的创建，后来我就放弃了在桌面版的输入体验了。现在我主要在手机上保留了生活类相关的任务，工作相关的数据尽可能不放在上面，除非电脑不在旁边但是又想起了什么。

我认为手机一直都不是一个很好的打字窗口，体验碎得一地，还要看 app 做得怎么样，所以我一直不看好在手机上做编辑器的类 app，这部分我之前也记录过[一些想法]({% post_url 2021-03-07-prefer-note-taking-app %})。

Todo list 还在继续增长，维护无序的平台和数据格式让我很头痛，直到我遇见了它，**[Taskwarrior](https://taskwarrior.org)**。毫不掩饰地说，我爱死这货了！最初遇见的几天我满脑子都是它，到底要怎样认识它，怎样和它相处，怎样和它擦出火花。



#### Taskwarrior

这并不是一篇介绍 taskwarrior 日常用法的文章，实际上我也做不到很全面概括地把它描述出来。我只是希望把它当成一个引子，把它抛出来供大家参考：有这样**一个神奇的开源 CLI 工具，它专注于只做一件事情：定义 todo item 格式，提供各种读写操作来管理他们，并帮助生成统计报告**。只此，无它。其他功能像堆积木一样在它的基础上不断地描绘出来，有官方的，也有非官方的。这就是优秀工具的样子，也是开源最优雅的地方。

要认识它推荐两个入口：

1. 官方的 [docs](https://taskwarrior.org/docs/)

2. 安装之后看 `man task`

   *这个 man page 真的是太会讲故事了，推荐读。*

Taskwarrior 的拓展还提供了各种形态的交互，有 TUI，shell，web 等各种版本。`task` 本身不支持数据同步的服务，但是官方通过 [`taskserver`](https://taskwarrior.org/docs/taskserver/why.html) 提供了一套数据同步服务，这个功能目前我没有用过。主要是觉得服务器部署有些麻烦，目前用的阿里云T5保不准我就不会再续了，到时候还需要迁移数据。



#### Data Sync

我勉强算是一个 git 重度用户了，很久以前就把各种文档类数据往 git / github 上[扔]({% post_url 2021-03-07-prefer-note-taking-app %})，自己手写过类似的同步脚本。这样的*变态*肯定不只我一个，这次 google 了一下发现了好多同类，有针对 taskwarrior 的，也有针对通用文本类数据的。[git-sync](https://worthe-it.co.za/blog/2016-08-13-automated-syncing-with-git.html) 就是后者，对比了好几个版本的同类脚本后，我认为这个版本是严格基于 git 日常操作执行的最规范版本。简单描述一下：通过指定需要同步的分支和对应的配置，然后在执行 `git-sync` 的时候就会把当前匹配修改的文件自动 commit & rebase & push。当然如果 merge 的时候还是有冲突，那还是需要手动解决。

`task` 还支持几种简单的 hook，虽然没有 git hook 那么完整，但是对于我目前的数据同步的需求还是够用的。默认情况下 `git-sync` 产生的 commit message 是毫无意义的，但是基于 task hook 我们可以让 commit message 变得有意义起来。

> 这也是我为什么最终没有用 `fswatch` 来触发文件改动的原因，用原生的 command context 更有意义。

我参考了一些同类功能的 hook 脚本，比如[这个](https://github.com/amracks/tgs/blob/master/on-exit.tgs.sh)和[这个](https://github.com/mrschyte/taskwarrior-hooks/tree/master/hooks)，但是他们都做的不够细致，所以我基于 `git-sync` 和 `task` hooks 做了一个结合。**项目在这里：[taskwarrior-data](https://github.com/xingheng/taskwarrior-data)**，这是一个模板类的项目仓库，纯粹使用的话推荐不要直接 fork 而使用文档里写的 clone & checkout 流程。因为 github fork 的话就没办法直接修改项目的可见性了，只能是 public 可见。仓库有两个分支，`dev` 分支是纯粹的脚本改动，`master` 分支是基于 `dev` 之上加了一些 demo task 数据，仅供初次部署演示用。如果想接收日后更新升级脚本的话，建议不要在个人的数据仓库里面删除 origin remote，不想保留的话可以直接 star 好了。

描述一下完整执行流程：

1. `task` 在执行的时候会首先读取它的 rc 配置文件，找到数据的存储路径，然后开始执行 `on-launch` hook：

   它传给 `on-launch-sync` 脚本一些 `task` [执行环境的参数](https://taskwarrior.org/docs/hooks.html)，这个时候脚本就会检查当前的数据仓库是否已经按照文档部署正确了，同时检查当前仓库是不是干净的（`git status` 输出没有修改任何文件，包括 staged & unstaged ）。如果部署不正确或者不干净的话就直接打断 `task` 后面的执行。

2. 正常执行 `task` 指定的命令。

   命令可以分两类：读和写。读操作自然不会触发 `on-add` 和 `on-modify` 这两个 hook，只有写操作会。这两个 hook 目前我都没有用的，只用了 `on-exit` hook 在最终统一处理数据同步，不涉及修改 `task` 任务本身的环境参数。

3. `task` 命令执行完之后在退出之前会触发 `on-exit` hook。

   这也是 `taskwarrior-data` 数据同步的最重要入口。它会去 `git diff` 看看当前数据仓库的工作区是否有文件变化，如果是写操作的话就一定有。然后把当前的 `task` 命令和完整执行环境参数全部打包作为 commit message 提交到 git 仓库，到这一步都是这些命令都是同步执行的，也就是说会阻塞 `task` 的执行流程，为了让数据在提交之前不会发生冲突，同时 `git diff` 和 `git commit` 也不会很耗时。接下来需要 `git push` 到远端，这个操作通常是比较耗时的，`git push` 多次也不会有什么影响，所以把这一步放在了后台操作，这样 `task` 在正常执行过程中这部分逻辑几乎是无感的。

4. 日志输出。

   在调试的时候和查问题的时候经常不知道 `git-sync` 到底做了什么操作，hook 都是什么时候触发的，所以增加了写日志操作。路径在数据仓库根目录下的 `git-sync.log` 。

5. 🚀🚀🚀



![wall-e and eve’s happy ending](/images/walle-eve-2.jpeg)

这一系列流程走下来目前是没有什么问题的，但是也不是没有优化的空间。比如如果 `git-sync` 在后台模式下执行完毕后发现有冲突，如果没有提示的话就只能手动等到下次 `task` 的时候通过 `on-launch-sync` 才能发现问题了，这种情况考虑后续加入 `say` 和/或 `osascript -e 'display notification'` 来通知用户了。`taskrc` 不仅可以用来配置 `task` 本身的行为，也可以被其他插件使用和读取，后续有一些可控的配置会考虑往里加入支持。



#### Security Issue

Taskwarrior 完全把数据交给了用户自己处理，用 taskserver 的话就自行管理好服务器的安全。用 git 托管的话就看用户自己的鉴权方式了。这是一般的鉴权级数据安全，还有另一层安全问题分级。一些企业安全部门会明令禁止所有内部数据不要托管在第三方平台，只能使用自家部署好的服务或者直接存在工作电脑里。这种情况就直接和主流的数据平台服务说再见了，除非他们支持自托管版本（比如 Bitwarden），同时还需要说服 IT 部门部署，更是难上加难了。使用 git 自托管的话这个时候的优势就在于一般 IT 公司一定会有自己信赖的代码托管平台，在已有的平台基础上申请创建一个代码仓库的难度一定比前者小得多。**让安全部门的人闭嘴**。



#### More

`Taskwarrior` 出自 [Göteborg Bit Factory](https://github.com/GothenburgBitFactory) 团队，他们也写了另一个追踪和统计时间的项目叫 [Timewarrior](https://timewarrior.net/)。这个工具我暂时用得不多，但是它的设计理念我是非常认同的，有兴趣的可以去读它的文档和 man page。

最后，分享一篇最近读到的优秀文章吧：[Stay Calm and Learn This](https://patrickjuchli.com/en/posts/learning-experience/) 。