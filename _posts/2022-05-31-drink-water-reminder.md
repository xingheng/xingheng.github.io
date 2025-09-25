---
layout: page
title: Drink water reminder
description: 我用过的有用的脚本(7)
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



> Time to drink some water…



#### Drink reminder

这种功能的 app 就有很多了，但是在办公室如果是在手机上发出来的提醒会比较弱，我甚至会觉得是一种干扰，所以索性也移到了 mac 里。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>willhan.drink.reminder</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/osascript</string>
		<string>-e</string>
		<string>display notification "🙋⏱🤜🤛🥃💪🤨😋🥳" with title "🍺🍺🍺 Drink Time 🍺🍺🍺" subtitle "" sound name "Glass"</string>
	</array>
	<key>RunAtLoad</key>
	<false/>
	<key>StartCalendarInterval</key>
	<array>
	    <dict>
	        <key>Hour</key>
	        <integer>10</integer>
	        <key>Minute</key>
	        <integer>30</integer>
	        <key>Second</key>
	        <integer>0</integer>
	    </dict>
	    <dict>
	        <key>Hour</key>
	        <integer>11</integer>
	        <key>Minute</key>
	        <integer>30</integer>
	        <key>Second</key>
	        <integer>0</integer>
	    </dict>
	    <dict>
	        <key>Hour</key>
	        <integer>14</integer>
	        <key>Minute</key>
	        <integer>30</integer>
	        <key>Second</key>
	        <integer>0</integer>
	    </dict>
	    <dict>
	        <key>Hour</key>
	        <integer>16</integer>
	        <key>Minute</key>
	        <integer>0</integer>
	        <key>Second</key>
	        <integer>0</integer>
	    </dict>
	    <dict>
	        <key>Hour</key>
	        <integer>18</integer>
	        <key>Minute</key>
	        <integer>30</integer>
	        <key>Second</key>
	        <integer>0</integer>
	    </dict>
	</array>
	<key>Nice</key>
	<integer>-10</integer>
	<key>StandardErrorPath</key>
	<string>/tmp/willhan.drink.reminder.log</string>
	<key>StandardOutPath</key>
	<string>/tmp/willhan.drink.reminder.log</string>
</dict>
</plist>
```

把它放到 `~/Library/LaunchAgents` 里，通过 `launchctl` 来管理。

```bash
launchctl load ~/Library/LaunchAgents/willhan.drink.reminder.plist
launchctl start willhan.drink.reminder
```



#### Example

> 自动触发。
