---
layout: page
title: Batch download the NARUTO videos
description: “批量下载火影忍者动画"
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink: 
tags: [unix, shell, command-line, crawler]
comments: true
reading_time: true
modified: 2020-05-30
---


#### 背景

下午从某个搞笑视频里听到火影忍者里面的OP，突然很想重温一下其中的一部分剧情，想起几年前最后一次更新的本地库里的集数并不全，有些集数还因为数据来源混乱的原因分辨率特别差。索性想办法这次更新一个完整集合，结合我最近知道的一个爬数据利器。

非(shi)常(zai)感(bao)谢(qian)优酷为我们提供的数据支撑，目前我看到的是所有数据全部无限制可播，所以我应该不用考虑VIP权限和cookie的问题了。下载方法优先想到的是[you-get](https://github.com/soimort/you-get)，虽然下载过程中发现有些问题，不过还是想办法绕了过去。其中最大的问题就是`--playlist / -l`没有生效，貌似是输入url类型不对，不过我始终找不到优酷关于这个播放列表的页面逻辑，貌似并不存在想youtube那样的playlist的单独页面，它只有单集的播放页面，播放列表是嵌套在所有单集页面的右侧的，`you-get`目前的实现可能还没有覆盖到那一部分数据解析，所以始终提示我找不到下一集。

不想在这个时候去给他们修bug，只能想办法手动找到所有单集的页面地址，然后一一传给`you-get`去处理了。找了前几集的页面url看了一下规则，也是有规则可寻的，但是优酷在集数之外又有一层分组的逻辑，比如第1-30是第一部分，第31-60是第二部分，依次类推…每个部分的单集url又不一样，这就开始无聊了….我尝试直接在shell里用for生成批量的url然后下载，有两个问题，每个集数部分的URL会不一样，我需要重新不断更换格式化字符串，其次是页面中目前的url中夹杂着特殊符号包括`!`和 `~`，这些符号好像会在shell里面直接被展开，加双引号都没起作用。直接放弃了。



#### Web Scraper

祭出大杀器[Web Scraper](https://chrome.google.com/webstore/detail/web-scraper/jnhgnonknehpejjnehehllkliplmbmhn)，之前看了官方的几个引导视频，但是目前还是不会用太高级的功能，就直接从最基础的操作入口。`Create new sitemap` -> `Input a start-url ` -> `Add new selector` -> `Input a name` -> `Select type as Link` -> `Select elements interactively` -> `Save selector` -> `Scrape` -> `Export data as CSV` -> `Download`, 详细的操作指南这里就不记录了，一顿操作之后我拿到了第一部分的集数数据，大概是这样子的：

```csv
web-scraper-order,web-scraper-start-url,item-link,item-link-href
"1590847460-7","https://v.youku.com/v_show/id_XNTI4NjExNDA4.html?spm=a2hbt.13141534.0.13141534&s=cc001f06962411de83b1","7","https://v.youku.com/v_show/id_XNTI4NjEyMTQw.html?s=cc001f06962411de83b1"
"1590847460-22","https://v.youku.com/v_show/id_XNTI4NjExNDA4.html?spm=a2hbt.13141534.0.13141534&s=cc001f06962411de83b1","22","https://v.youku.com/v_show/id_XNTI4NjIxNDEy.html?s=cc001f06962411de83b1"
"1590847460-29","https://v.youku.com/v_show/id_XNTI4NjExNDA4.html?spm=a2hbt.13141534.0.13141534&s=cc001f06962411de83b1","29","https://v.youku.com/v_show/id_XNTI4NjIzNDcy.html?s=cc001f06962411de83b1"
"1590847460-14","https://v.youku.com/v_show/id_XNTI4NjExNDA4.html?spm=a2hbt.13141534.0.13141534&s=cc001f06962411de83b1","14","https://v.youku.com/v_show/id_XNTI4NjE0MTgw.html?s=cc001f06962411de83b1"
...
```

前面两列的数据分别是集数的序号和爬取页面的地址，对我没有意义，主要是需要第三列的集数号和第四列的页面地址。



#### 下载

先用`you-get`试试效果怎样：

```shell
awk -F ',' 'NR>1 {print $4}' youku-naruto.csv | xargs -I{} you-get -anf --no-caption {}
```

首先要从csv文件中取到第四列的数据并且传给you-get，所以第一个awk主要负责数据过滤就行了，`NR>1`是为了过滤csv文件中的第一行头部数据。后面的`you-get`主要负责下载单集视频即可，其中视频下载的过程是通过分片下载的，但是`you-get`目前的merge操作出问题了，大致原因是从优酷拿到的response header里面的type并不在下载器目前配置的type list里面，所以无法merge成功，所以指定了`-n`标识不需要merge，只能想办法后面通过`ffmpeg`甚至`cat`解决了。`-f`标识强制覆盖本地已有的文件，`-a`是自动重命名。`--no-caption`标识不需要下载任何字幕和弹幕等数据。

批量下载成功，但是下载下来的视频文件都是每一集的中文名，没有集码，这个我实在不能接受，毕竟之后本地播放器一定是根据字符串的排序来决定在播放列表中的顺序的。那就先暂定用集数作输出视频的文件名，给`you-get`指定`-O`就好。所以优化了一下：

```shell
awk -F ',' 'NR>1 { system("you-get -anf --no-caption -O " $3 " " $4)}' youku-naruto.csv
```

因为需要同时从csv中提取两个参数给`you-get`，所以不能再用`xargs`了，只能通过awk的内置`system`函数启动`you-get`了，拼接好集码编号和url就行。

命名的问题解决了，但是下载的顺序还是无序的。这归根于`Web-Scraper`在爬取的时候的数据好像就是乱序的，具体什么原因还不清楚，不过我只能先手动解决排序了。

```shell
awk -F ',' 'NR>1 { print $3, $4}' youku-naruto.csv | sort | awk '{ system("you-get -anf --no-caption -O " $1 " " $2)}'
```

先从csv中把集码和url拿到，把集码放在输出先前，然后通过管道传给`sort`直接排序，最后再取到对应的数据传给awk嵌套的you-get。因为第一个awk已经把有效的数据过滤出来了，所以在第二个awk里面直接取第一二部分就可以，另外第一个awk里面在print的时候用了空格做分隔，所以第二个awk里面可以直接使用默认分隔符就好了。



#### 合并碎片

终于开始批量下载了，前30集的结果大概是这个样子。

```bash
➜  1-30 find . -type f | sort | xargs -n 7
./10[00].mp4 ./10[01].mp4 ./10[02].mp4 ./10[03].mp4 ./10[04].mp4 ./10[05].mp4 ./10[06].mp4
./11[00].mp4 ./11[01].mp4 ./11[02].mp4 ./11[03].mp4 ./11[04].mp4 ./11[05].mp4 ./11[06].mp4
./12[00].mp4 ./12[01].mp4 ./12[02].mp4 ./12[03].mp4 ./12[04].mp4 ./12[05].mp4 ./12[06].mp4
./13[00].mp4 ./13[01].mp4 ./13[02].mp4 ./13[03].mp4 ./13[04].mp4 ./13[05].mp4 ./13[06].mp4
./14[00].mp4 ./14[01].mp4 ./14[02].mp4 ./14[03].mp4 ./14[04].mp4 ./14[05].mp4 ./14[06].mp4
./15[00].mp4 ./15[01].mp4 ./15[02].mp4 ./15[03].mp4 ./15[04].mp4 ./15[05].mp4 ./15[06].mp4
./16[00].mp4 ./16[01].mp4 ./16[02].mp4 ./16[03].mp4 ./16[04].mp4 ./16[05].mp4 ./16[06].mp4
./17[00].mp4 ./17[01].mp4 ./17[02].mp4 ./17[03].mp4 ./17[04].mp4 ./17[05].mp4 ./17[06].mp4
./18[00].mp4 ./18[01].mp4 ./18[02].mp4 ./18[03].mp4 ./18[04].mp4 ./18[05].mp4 ./18[06].mp4
./19[00].mp4 ./19[01].mp4 ./19[02].mp4 ./19[03].mp4 ./19[04].mp4 ./19[05].mp4 ./19[06].mp4
./1[00].mp4 ./1[01].mp4 ./1[02].mp4 ./1[03].mp4 ./1[04].mp4 ./1[05].mp4 ./1[06].mp4
./20[00].mp4 ./20[01].mp4 ./20[02].mp4 ./20[03].mp4 ./20[04].mp4 ./20[05].mp4 ./20[06].mp4
./21[00].mp4 ./21[01].mp4 ./21[02].mp4 ./21[03].mp4 ./21[04].mp4 ./21[05].mp4 ./21[06].mp4
./22[00].mp4 ./22[01].mp4 ./22[02].mp4 ./22[03].mp4 ./22[04].mp4 ./22[05].mp4 ./22[06].mp4
./23[00].mp4 ./23[01].mp4 ./23[02].mp4 ./23[03].mp4 ./23[04].mp4 ./23[05].mp4 ./23[06].mp4
./24[00].mp4 ./24[01].mp4 ./24[02].mp4 ./24[03].mp4 ./24[04].mp4 ./24[05].mp4 ./24[06].mp4
./25[00].mp4 ./25[01].mp4 ./25[02].mp4 ./25[03].mp4 ./25[04].mp4 ./25[05].mp4 ./25[06].mp4
./26[00].mp4 ./26[01].mp4 ./26[02].mp4 ./26[03].mp4 ./26[04].mp4 ./26[05].mp4 ./26[06].mp4
./26[07].mp4 ./27[00].mp4 ./27[01].mp4 ./27[02].mp4 ./27[03].mp4 ./27[04].mp4 ./27[05].mp4
./27[06].mp4 ./28[00].mp4 ./28[01].mp4 ./28[02].mp4 ./28[03].mp4 ./28[04].mp4 ./28[05].mp4
./28[06].mp4 ./29[00].mp4 ./29[01].mp4 ./29[02].mp4 ./29[03].mp4 ./29[04].mp4 ./29[05].mp4
./29[06].mp4 ./30[00].mp4 ./30[01].mp4 ./30[02].mp4 ./30[03].mp4 ./30[04].mp4 ./30[05].mp4
./30[06].mp4 ./3[00].mp4 ./3[01].mp4 ./3[02].mp4 ./3[03].mp4 ./3[04].mp4 ./3[05].mp4
./3[06].mp4 ./4[00].mp4 ./4[01].mp4 ./4[02].mp4 ./4[03].mp4 ./4[04].mp4 ./4[05].mp4
./4[06].mp4 ./5[00].mp4 ./5[01].mp4 ./5[02].mp4 ./5[03].mp4 ./5[04].mp4 ./5[05].mp4
./5[06].mp4 ./6[00].mp4 ./6[01].mp4 ./6[02].mp4 ./6[03].mp4 ./6[04].mp4 ./6[05].mp4
./6[06].mp4 ./7[00].mp4 ./7[01].mp4 ./7[02].mp4 ./7[03].mp4 ./7[04].mp4 ./7[05].mp4
./7[06].mp4 ./8[00].mp4 ./8[01].mp4 ./8[02].mp4 ./8[03].mp4 ./8[04].mp4 ./8[05].mp4
./8[06].mp4 ./9[00].mp4 ./9[01].mp4 ./9[02].mp4 ./9[03].mp4 ./9[04].mp4 ./9[05].mp4
./9[06].mp4 ./main.py ./我是木叶丸[00].mp4 ./我是木叶丸[01].mp4 ./我是木叶丸[02].mp4 ./我是木叶丸[03].mp4 ./我是木叶丸[04].mp4
./我是木叶丸[05].mp4 ./我是木叶丸[06].mp4
```

本来是期望`xargs -n 7`就可以直接针对每一集的7个碎片文件进行分组然后直接`cat`，但是仔细看了结果才发现第26集居然有7个碎片，不确定后面有没有类似这种情况的出现，想了半天也没有什么好的办法能直接在bash里面做这种group by的操作，有点尴尬，最后还是不得不借助Python来处理。用Python内置的`set`类型想来是更方便的。

```python
import sys

files = [x.rstrip() for x in sys.stdin.readlines()]
prefixes = set(map(lambda x: x[:x.index('[')], files))
groups = [[y for y in files if y.startswith(x + '[')] for x in prefixes]
print(reduce(lambda sum, x: sum + ' '.join(sorted(x)) + '\n', groups, ''))
```

把`find`的结果继续pipe到python脚本，分组终于告一段落了。

```bash
➜  1-30 find . -type f -name "*.mp4" | python ../main.py
Alias tip: ff "*.mp4" | python ../main.py
./我是木叶丸[00].mp4 ./我是木叶丸[01].mp4 ./我是木叶丸[02].mp4 ./我是木叶丸[03].mp4 ./我是木叶丸[04].mp4 ./我是木叶丸[05].mp4 ./我是木叶丸[06].mp4
./8[00].mp4 ./8[01].mp4 ./8[02].mp4 ./8[03].mp4 ./8[04].mp4 ./8[05].mp4 ./8[06].mp4
./9[00].mp4 ./9[01].mp4 ./9[02].mp4 ./9[03].mp4 ./9[04].mp4 ./9[05].mp4 ./9[06].mp4
./4[00].mp4 ./4[01].mp4 ./4[02].mp4 ./4[03].mp4 ./4[04].mp4 ./4[05].mp4 ./4[06].mp4
./5[00].mp4 ./5[01].mp4 ./5[02].mp4 ./5[03].mp4 ./5[04].mp4 ./5[05].mp4 ./5[06].mp4
./6[00].mp4 ./6[01].mp4 ./6[02].mp4 ./6[03].mp4 ./6[04].mp4 ./6[05].mp4 ./6[06].mp4
./7[00].mp4 ./7[01].mp4 ./7[02].mp4 ./7[03].mp4 ./7[04].mp4 ./7[05].mp4 ./7[06].mp4
./1[00].mp4 ./1[01].mp4 ./1[02].mp4 ./1[03].mp4 ./1[04].mp4 ./1[05].mp4 ./1[06].mp4
./3[00].mp4 ./3[01].mp4 ./3[02].mp4 ./3[03].mp4 ./3[04].mp4 ./3[05].mp4 ./3[06].mp4
./23[00].mp4 ./23[01].mp4 ./23[02].mp4 ./23[03].mp4 ./23[04].mp4 ./23[05].mp4 ./23[06].mp4
./22[00].mp4 ./22[01].mp4 ./22[02].mp4 ./22[03].mp4 ./22[04].mp4 ./22[05].mp4 ./22[06].mp4
./21[00].mp4 ./21[01].mp4 ./21[02].mp4 ./21[03].mp4 ./21[04].mp4 ./21[05].mp4 ./21[06].mp4
./20[00].mp4 ./20[01].mp4 ./20[02].mp4 ./20[03].mp4 ./20[04].mp4 ./20[05].mp4 ./20[06].mp4
./27[00].mp4 ./27[01].mp4 ./27[02].mp4 ./27[03].mp4 ./27[04].mp4 ./27[05].mp4 ./27[06].mp4
./26[00].mp4 ./26[01].mp4 ./26[02].mp4 ./26[03].mp4 ./26[04].mp4 ./26[05].mp4 ./26[06].mp4 ./26[07].mp4
./25[00].mp4 ./25[01].mp4 ./25[02].mp4 ./25[03].mp4 ./25[04].mp4 ./25[05].mp4 ./25[06].mp4
./24[00].mp4 ./24[01].mp4 ./24[02].mp4 ./24[03].mp4 ./24[04].mp4 ./24[05].mp4 ./24[06].mp4
./29[00].mp4 ./29[01].mp4 ./29[02].mp4 ./29[03].mp4 ./29[04].mp4 ./29[05].mp4 ./29[06].mp4
./28[00].mp4 ./28[01].mp4 ./28[02].mp4 ./28[03].mp4 ./28[04].mp4 ./28[05].mp4 ./28[06].mp4
./30[00].mp4 ./30[01].mp4 ./30[02].mp4 ./30[03].mp4 ./30[04].mp4 ./30[05].mp4 ./30[06].mp4
./18[00].mp4 ./18[01].mp4 ./18[02].mp4 ./18[03].mp4 ./18[04].mp4 ./18[05].mp4 ./18[06].mp4
./19[00].mp4 ./19[01].mp4 ./19[02].mp4 ./19[03].mp4 ./19[04].mp4 ./19[05].mp4 ./19[06].mp4
./16[00].mp4 ./16[01].mp4 ./16[02].mp4 ./16[03].mp4 ./16[04].mp4 ./16[05].mp4 ./16[06].mp4
./17[00].mp4 ./17[01].mp4 ./17[02].mp4 ./17[03].mp4 ./17[04].mp4 ./17[05].mp4 ./17[06].mp4
./14[00].mp4 ./14[01].mp4 ./14[02].mp4 ./14[03].mp4 ./14[04].mp4 ./14[05].mp4 ./14[06].mp4
./15[00].mp4 ./15[01].mp4 ./15[02].mp4 ./15[03].mp4 ./15[04].mp4 ./15[05].mp4 ./15[06].mp4
./12[00].mp4 ./12[01].mp4 ./12[02].mp4 ./12[03].mp4 ./12[04].mp4 ./12[05].mp4 ./12[06].mp4
./13[00].mp4 ./13[01].mp4 ./13[02].mp4 ./13[03].mp4 ./13[04].mp4 ./13[05].mp4 ./13[06].mp4
./10[00].mp4 ./10[01].mp4 ./10[02].mp4 ./10[03].mp4 ./10[04].mp4 ./10[05].mp4 ./10[06].mp4
./11[00].mp4 ./11[01].mp4 ./11[02].mp4 ./11[03].mp4 ./11[04].mp4 ./11[05].mp4 ./11[06].mp4
```

接下来只要把分组后每一行的结果拼成一个文件就可以了，这个时候又有一个问题，生成的文件名我应该如何定义和取到，想了想最后还是直接在python里面一起输出了，直接放在行首。既然文件名都输出了，为什么不直接把`cat`/`ffmpeg`的命名部分一次性合成呢？

```python
from __future__ import print_function
import sys

files = sorted([x.rstrip() for x in sys.stdin.readlines()])
prefixes = sorted(set(map(lambda x: x[:x.index('[')], files)))

for prefix in prefixes: 
    print('echo "', end='')

    for file in files:
        if file.startswith(prefix + '['):
            print('file \'%s\'\\n' % file, end=' ')

    print('"| ffmpeg -protocol_whitelist file,pipe -safe 0 -f concat -i pipe: -c copy ' + prefix + '.mp4')
```

至此，每一集的合成命令大概是这样的：

```bash
echo "file './1[00].mp4' \\nfile './1[01].mp4' \\nfile './1[02].mp4' \\nfile './1[03].mp4' \\nfile './1[04].mp4' \\nfile './1[05].mp4' \\nfile './1[06].mp4' \\nfile './1[07].mp4' \\n"| ffmpeg -protocol_whitelist file,pipe -safe 0 -f concat -i pipe: -c copy ./1.mp4
```

为什么没有用`cat`？我试了一下，合成的文件是可以无缝跳转播放的，文件大小也符合预期，但是在播放器里面无法seek（到第二个视频碎片之后的内容），猜测原因是`cat`只是在数据上的合并，但是最后输出的时候没有给输出文件修改视频本身相关的meta data，毕竟`cat`是专门针对所有的通用文件的，视频文件的合并处理最终还是需要`ffmpeg`。

> [**Concatenation of files with same codecs**](https://trac.ffmpeg.org/wiki/Concatenate#samecodec)
>
> There are two methods within ffmpeg that can be used to concatenate files of the same type:
>
> 1. [the concat ''demuxer''](https://trac.ffmpeg.org/wiki/Concatenate#demuxer)
> 2. [the concat ''protocol''](https://trac.ffmpeg.org/wiki/Concatenate#protocol)
>
> The demuxer is more flexible – it requires the same codecs, but different container formats can be used; and it can be used with any container formats, while the protocol only works with a select few containers.
>
> While the demuxer works at the stream level, the concat protocol works at the file level.

> 关于pipe protocol的使用定义，参见 [ffmpeg protocols](https://ffmpeg.org/ffmpeg-protocols.html#toc-pipe)。

接下来把合成的语句pipe到下一个命令，这里用xargs处理。

```bash
find . -type f -name "*.mp4" | python ../main.py | xargs -I{} sh -c "{}"
```

合并完成。



#### 中文问题

*To be continued.*

