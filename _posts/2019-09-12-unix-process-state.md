---
layout: page
title: Unix Process State
description: “Send kinds of signals to process to change its state."
image:
  path: http://example.jpg
  feature: unix_process_state.jpg
  credit: Department of Computer Science | University of IIIinois at Chicago
  creditlink: https://www.cs.uic.edu/~jbell/CourseNotes/OperatingSystems/3_Processes.html
tags: [unix, shell, command-line]
comments: true
reading_time: true
modified: 2019-09-12
---



### 问题

有时候会在晚上睡觉之前开始在mac mini上下几个大文件或者跑`brew update`，等命令跑到一半发现不想再继续等下去了，因为等待的时间比预期的远远要长。我又不想因为一句命令让机器一整晚上都运行着，还是想着应该让这个命令结束之后再立刻休眠（`pmset sleepnow`）。

于是问题来了，我要么找到结束当前正在一直运行的这个命令再重新编辑（追加`&& pmset sleepnow`）达到效果，要么想办法找到那个进程执行完毕的那个时间点。其实对于`brew update`这类命令的话，结束执行再跑一点儿关系都没有，主要还是针对`curl`和封装了`curl`的任务，毕竟杀掉了重新来过一般只能重新开始。



### 思路

在这之前我是知道`jobs`, `fg`和`bg`这几个常用命令的：一个在运行的程序，如果我发送Ctrl+Z的组合时间给它，就相当于挂起（suspend）了这个进程，这个时候开始它只能等待恢复（或者直接被杀掉）。`jobs`能直接查看到当前shell的进程列表中所有的任务列表，通过`fg`可以把最顶端挂起的任务恢复并分发到前台运行模式，相当于把目标任务提到了当前shell的正在执行的命令模式，相当于接替上一个状态继续执行。`bg`的作用基本一致，区别在于目标任务被分到了后台运行模式，当前shell仍然处于带输入模式接受下一个命令的执行。如果不考虑stdout或者目标任务的stdout被重定向到了其他文件，`bg`会表现得目标任务不存在一样，直到执行完毕会从后台运行模式下输出一个进程执行完毕的提示。

以`sleep`举例：

```shell
➜  ~ sleep 30 && echo "I'm done"
^Z
[1]  + 18342 suspended  sleep 30
➜  ~ jobs
[1]  + suspended  sleep 30
➜  ~ fg
[1]  + 18342 continued  sleep 30
^Z
[1]  + 18342 suspended  sleep 30
➜  ~ bg
[1]  + 18342 continued  sleep 30
➜  ~
[1]  + 18342 done       sleep 30
➜  ~
```

[DND](https://objective-see.com/products/dnd.html) 的触发逻辑就是这样的：允许目标进程启动，但是又立刻挂起，等待用户授权完成之后再恢复它。



### 解决方法

1. `fg && echo "Going to sleep..." && pmset sleep`

   直接把`fg`当做目标任务的一个handler，`fg`在执行的时候相当于是把目标进程同步地dispatch到当前的主shell进程上来运行，直到目标进程执行完毕`fg`的任务才算完毕。然后继续下一个shell命令...

2. `wait`, 上面说到的是同步地dispatch到主shell进程上来，那就应该有异步执行的操作然后在主线程等待（join）的信号处理方法。`wait`就是做这件事情的，但它也有自己的使用规则。

   `wait`接收一个进程id（pid）并等待目标进程的完成状态，但是这个pid必须是当前shell的子进程。`wait`不改变目标进程的运行模式和状态，它只是单纯地observe一个进程终止状态并作为返回值返回。所以我的问题也可以这么解决：

   ```shell
   ➜  ~ sleep 30 && echo "I'm done"
   ^Z
   [1]  + 55241 suspended  sleep 30
   ➜  ~ bg
   [1]  + 55241 continued  sleep 30
   ➜  ~ wait 55241 && echo "Going to sleep..." && pmset sleep
   [1]  + 55241 done       sleep 30
   gogo
   ➜  ~
   ```
   
3. [Composer](https://www.iterm2.com/documentation-status-bar.html) component in iTerm2’s status bar

   这个功能是从iTerm2的3.3.0版本开始加入的，和上面的方式不同，它是以延迟式键盘事件的方式发送到当前shell的命令行然后回车执行的，这就相当于不用等待当前shell正在运行的进程终止，提前准备好接下来的输入然后发送。

   想到发送输入的情形就得把`read`的情形考虑进来，也就是说如果当前正在运行的命令包含一个交互式的等待用户输入以继续的逻辑，那么iTerm会如何处理呢？试一试：

   ```shell
   ➜  ~ ping www.baidu.com -t 5; read -n a; echo "Your input: $a"
   PING www.a.shifen.com (39.156.66.14): 56 data bytes
   64 bytes from 39.156.66.14: icmp_seq=0 ttl=53 time=8.710 ms
   64 bytes from 39.156.66.14: icmp_seq=1 ttl=53 time=9.165 ms
   date
   date
   64 bytes from 39.156.66.14: icmp_seq=2 ttl=53 time=8.611 ms
   64 bytes from 39.156.66.14: icmp_seq=3 ttl=53 time=8.332 ms
   64 bytes from 39.156.66.14: icmp_seq=4 ttl=53 time=11.044 ms
   
   --- www.a.shifen.com ping statistics ---
   5 packets transmitted, 5 packets received, 0.0% packet loss
   round-trip min/avg/max/stddev = 8.332/9.172/11.044/0.973 ms
   Your input: date
   ➜  ~ date
   Thu Sep 26 22:47:17 CST 2019
   ➜  ~
   ```

   结果出来了，过程中我用`ping`的目的只是为了延迟`read`的执行时间并加入一些输出，我在Composer组件里输出了`date`然后立刻回车了两次。这部分内容混杂到了整个session输出里面，但是第一个`date`以字符串的方式被read接收然后打印了出来，第二个`date`以命令的方式发送到了执行完毕之后的交互模式开始了一个新的shell任务。

   这个行为可以这么理解，从[macOS Foundation `NSRunLoop`](https://developer.apple.com/documentation/foundation/nsrunloop)的原理上来看，iTerm当前shell的window或者tab在处理当前的自己的keyboard event loop的时候，会不断地询问当前运行模式下是否能处理输入事件，如果能的话就发送Composer队列里的第一个字符串到event loop中，从上面的例子可以看出来至少在处理`read`和普通模式的等待执行命令这两种情形是能处理的，然后结束Composer在本次loop的任务。如果不能的话就继续在下一个loop继续询问，直到Composer队列里面的所有文本命令被发送成功。



### 结语

* `jobs`, `fg`, `bg`, `wait` 全部都是shell内置的命令，可能不同的shell在实现和行为上有些不同。以上环境是zsh的执行结果。

* 可以从上面的几个例子看到其实通常一句shell命令在提交到iTerm的主进程`launch_shell`的时候可以有两种方式：一种是单命令，比如`sleep 10`，运行的时候只会产生一个进程。另一种是`sleep 10 && echo "I’m done”`（把`&&`替换成`;`是一样的）或者用了循环语句的情形，产生多个进程（其实大多是这种情形）。

  如果是简单的单命令执行，用以上任意一种方法都可以满足；如果是复杂的多进程执行，推荐使用第三种iTerm2的Composer方法，毕竟不用考虑进程状态等问题，但是还是要考虑`read`的处理问题。当然了，如果只会产生一个主进程的话，用方法1和2也是可以的，只是需要确认一下。`pstree` with `watch`?
  
* 用`sleep`在上面的例子中测试并不是很好，据我测试Ctrl+Z对`sleep`并不能达到我期望的效果，貌似跟wall clock的行为有关，和我原本理解的按秒sleep有差别。



### 相关阅读：

*  [Linux Process States](https://idea.popcount.org/2012-12-11-linux-process-states/)
* [Linux / Unix: jobs Command Examples](https://www.cyberciti.biz/faq/unix-linux-jobs-command-examples-usage-syntax/)