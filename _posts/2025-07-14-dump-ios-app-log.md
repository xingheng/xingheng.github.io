---
layout: page
title: Dump iOS app log
description: null
image:
  path: http://example.jpg
  feature:
  credit:
  creditlink:
tags: [ios, log]
comments: true
reading_time: true
modified: 2025-07-14
---



## Background

Checking the live logs of an iOS app is still a pain, and I haven’t found a one-size-fits-all fix yet. While digging
around, though, I did pick up a few neat tricks.



## Console Log

Watching live logs in Console.app is easy enough, but the built-in tool can’t do advanced things like keyword filtering or blocking. My first idea was to find a command-line version and pipe it somewhere else. It turns out the `log` command exists—it just takes a few extra steps.

```bash
# Capture iOS device's system log via `log` command.
capture interval="10":
    #!/usr/bin/env bash

    export OS_ACTIVITY_MODE=disable
    export OS_ACTIVITY_STREAM=live

    interval={{interval}}
    CUR_TIME=$(/bin/date +"%Y-%m-%d %H:%M:%S")
    END_TIME=$(/bin/date -j -f "%Y-%m-%d %H:%M:%S" -v +${interval}S "$CUR_TIME" +"%Y-%m-%d %H:%M:%S")

    echo "CUR_TIME: $CUR_TIME"
    echo "END_TIME: $END_TIME"

    rm -fr system_logs.logarchive
    date +"%Y-%m-%d %H:%M:%S.%3N"

    sudo log collect --device --start "$CUR_TIME" --last "${interval}s" 
    
    date +"%Y-%m-%d %H:%M:%S.%3N"

    log show --archive system_logs.logarchive --start "$CUR_TIME" --end "$END_TIME" --predicate myapp-internal
```

I wrapped the whole thing with `just`. It has two simple steps:

1. Run `log collect` to grab a short-time log bundle.  
2. Run `log show` on that bundle and filter the lines I need.  

The `--predicate myapp` part is saved in `~/.logrc`, so I don’t type it every time.

```
show:
    --style compact
    --info
    --debug

predicate:
    myapp-internal
        'process == "MyApp" and '
        'sender == "MyApp.debug.dylib" '
```

Now I can filter like a pro, but I still can’t block noisy keywords—only `grep` can help there. Worse, I lose the ***live*** feel: I only see logs after a delay, not real time. And the whole dance needs `sudo`, so Apple has pretty much locked it down for safety and performance. Who knows when they’ll open it up? I had to look elsewhere.



## idevicesyslog

Luckily, the `idevice` family gives us `idevicesyslog`.  It streams the system log in real time, and you can write simple filter rules (they look almost like Apple’s, just a bit different).  It lets you **keep** keywords, but it can’t **drop** them. I first tried to pipe the output into `grep -v`, yet the buffer kept messing up the lines.  So I opened a small [PR](https://github.com/libimobiledevice/libimobiledevice/pull/1671) and added a `-M` switch: any keyword that follows `-M` will be blocked.  Use it like this:

```bash
idevicesyslog -p "MyApp" -m "MyApp.debug.dylib" \
  -M "[tpdlcore]" -M "[tpnative]" -M "[tpdlproxy]" -M "[tpvfs]" \
  {{args}}
```

Now I can filter and block keywords in real time—great!  But the next wall is unicode logs: our project prints tons of them, and `idevicesyslog` still can’t show Unicode right. It’s a well-known, years-old bug. After some digging I saw the raw stream really has no encoding hint; the tool just dumps whatever it sniffs from the device as UTF-8. A real fix looks messy, so for now I swallow the broken characters and keep working.



## CLILogger

In the end, I just pick the right tool for each moment.  Most of the time I stay inside my little [CLILogger](https://github.com/CLILogger/CLILogger): it sits on top of [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack), ships every log line over a plain TCP socket to a tiny server in the terminal, and lets me filter or block whatever I want, live.

The project has been running for years actually, yet I never wrote a proper “how-to”. I’ll squeeze out some weekend and fill that gap.
