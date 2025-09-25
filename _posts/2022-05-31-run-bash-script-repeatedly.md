---
layout: page
title: Run bash script repeatedly
description: 我用过的有用的脚本(1)
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

> Hey, your long-running command has been finished.


#### Loop

```bash
run() {
    declare -i number=$1
    declare -i i
    declare -i pid
    declare -i interrupted=0

    trap "echo Exiting...; interrupted=1" SIGINT SIGTERM SIGQUIT
    shift

    # Turn off "monitor mode" so the shell doesn't report terminating background jobs.
    set +m

    for ((i = 0; i < number; ++i)); do
        echo "\n-- Run ${i}th time --\n"
        $@ &
        pid=$!
        wait $pid

        # If we receive one of the signals, kill it and break
        [[ $interrupted == 1 ]] && kill $pid && break
    done

    # Switch back to default behaviour
    set -m
    trap - SIGINT SIGTERM SIGQUIT
}
```

其实就是给日常的命令加一个 `for` 循环，区别在于

* 方便调用，不需要每次单独地写同样的循环条件表达式了；
* 捕获信号量，只要有一次终止意图就立刻 `break` 整个循环，这并不是默认的，没有它的话在发送 `ctrl + c` 的时候循环还是会自动执行（因为 `SIGINT` 只是被 `$@ &` 捕获了，`for` 所在的进程会无视它的结果）；
* 有时候我想知道一个命令到底运行了多少次，通过简单的日志可以方便看出来。



基于它的变体还有另外两个方法：

```bash
retry()
{
    declare -i number=$1
    declare -i i
    declare -i pid
    declare -i interrupted=0

    trap "echo Exiting...; interrupted=1" SIGINT SIGTERM SIGQUIT
    shift

    # Turn off "monitor mode" so the shell doesn't report terminating background jobs.
    set +m

    for ((i = 0; i < number; ++i)); do
        echo "\n-- Retry ${i}th time --\n"
        $@ &
        pid=$!

        # If command succeeded, break
        wait $pid && break

        # If we receive one of the signals, kill it and break
        [[ $interrupted == 1 ]] && kill $pid && break
    done

    # Switch back to default behaviour
    set -m
    trap - SIGINT SIGTERM SIGQUIT
}

check()
{
    declare -i number=0
    declare last_output
    declare -i ret=-1
    trap "echo Exiting...; ret=1" SIGINT SIGTERM SIGQUIT

    # Turn off "monitor mode" so the shell doesn't report terminating background jobs.
    set +m

    while true; do
        declare output=$($@)
        number=$((number+1))

        # If we receive one of the signals...
        [[ $ret -ge 0 ]] && break

        if [[ $number -eq 1 ]]; then 
            echo "-- Check ${number}th time --"
        elif [[ $last_output == $output ]]; then
            echo -e "\e[1A\e[K-- Check ${number}th time --"
        else 
            echo -ne "\e[1A\e[K"
            ret=0
        fi

        last_output=$output
    done

    [[ -z $last_output ]] || echo -n $last_output

    # Switch back to default behaviour
    set -m
    trap - SIGINT SIGTERM SIGQUIT

    return $ret
}
```

`retry` 会自动执行指定命令n次，直到成功为止，它是基于上一次的命令结果是否为0来判定成功与否。

`check` 是在比较第一次和第 n(n>1) 次的输出内容是否有什么变化，如果有变化就终止。



#### Example

```bash
run 10 date
```

```bash
retry 100 nslookup www.google.com
```

```bash
check nc -vz localhost 9000
```
