---
layout: page
title: COVID-19 Report Analysis
description: “"
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink: 
tags: [python, command-line, crawler]
comments: true
reading_time: true
modified: 2020-06-23
---

#### 背景

上周去做了一个团体核算检测，三天后拿到了结果。直接从他们的机构的官方网站查询就行了，报告格式是PDF，因为整个过程除了**输入**身份证号和姓名之外，并没有其他的身份校验，所以好奇性地把最终报告的页面地址直接在隐身模式下打开，结果….有下文了，又是一个专门为爬虫设计的简单系统，前端是php，后台是Java。没有登录，没有验证码，没有请求次数限制，就好像是在说：**服务全开，全开！**

#### 下载

报告分移动端和PC端两个版本，仔细看了前端的JS脚本发现都是走的同一个接口，只不过移动端是把最终的pdf内容转成了图片格式。直接在Network inspector里面找到了下载报告的XHR请求，导出对应的curl命名，贴在命令行运行就可以直接运行了。参数大概是这样的（已脱敏）：

```shell
curl 'http://the/post/url' \
  -H 'Connection: keep-alive' \
  -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36' \
  -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundarybfGJ0I90Seu9Ywjc' \
  -H 'Accept: */*' \
  -H 'Origin: http://www.example.com' \
  -H 'Referer: http://www.example.com/reports/' \
  -H 'Accept-Language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,zh-TW;q=0.6' \
  --data-binary $'------WebKitFormBoundarybfGJ0I90Seu9Ywjc\r\nContent-Disposition: form-data; name="sampleNo"\r\n\r\nXFFFFFF000000\r\n------WebKitFormBoundarybfGJ0I90Seu9Ywjc--\r\n' \
  --compressed \
  --insecure
```

我尝试把这个request转成python requests的代码，[但是失败了](https://stackoverflow.com/q/62538257/1677041)，具体原因后面再查，不影响我先把报告批量爬下来。直接用python把这个curl命令封装一下就好了，因为是response type始终是PDF，所以需要考虑过滤一下错误的报告。如果请求了无效的报告编号，那最终的pdf是无效了，里面的内容其实一个JSON字符串，可以通过macOS下的`file`命令直接判定。很简单的逻辑，实现起来是这样子：

```python
def download_via_curl(order_id):
    'Download covid-19 report via curl.'
    filepath = os.path.join(DIR, order_id)

    if os.path.exists(filepath):
        return True, 'report exists'

    command = """curl 'http://the/post/url' \
-H 'Connection: keep-alive' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Safari/537.36' \
-H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundarygxQA506xLQ8L4PcZ' \
-H 'Accept: */*' \
-H 'Origin: http://www.example.com' \
-H 'Referer: http://www.example.com/reports/covid19/{id}/' \
-H 'Accept-Language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,zh-TW;q=0.6' \
-H 'dnt: 1' \
--data-binary $'------WebKitFormBoundarygxQA506xLQ8L4PcZ\\r\\nContent-Disposition: form-data; name="sampleNo"\\r\\n\\r\\n{id}\\r\\n------WebKitFormBoundarygxQA506xLQ8L4PcZ--\\r\\n' \
--compressed \
--insecure \
--output "{path}" \
--silent
  """.format(id=order_id, path=filepath)

    # logger.debug(command)
    p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    p.wait()

    if p.returncode != 0:
        return False, 'request error'

    def get_file_type(filepath):
        command = 'file -b %s' % filepath
        p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        p.wait()
        return p.stdout.read().rstrip()

    file_type = get_file_type(filepath)

    if 'PDF' in file_type:
        return True, None
    else:
        os.remove(filepath)
        return False, 'Invalid file type %s' % file_type
```

接下来只要找到根据我的报告编号的规则来生成一系列新的序号就可以了，同样为了不暴露敏感信息的原则，编号的规则基本是这样的：`XXXFFF000000`，前6位含字母和数字的应该是一个系列，猜测每一个团体大概率用的应该是同一个编号，后6位纯数字就是对应的针对被检测人的序号了。从有效数据开始遍历，我用我自己的编号先往前面遍历，再往后面遍历。就能拿到尽可能多的报告编号。

```python
def batch_download():
    prefix = 'XXXFFF'
    start = 100000
    idx, failure = start, 0

    while True:
        order_id = prefix + '%06d' % idx
        result, msg = download_via_curl(order_id)

        if result:
            logger.debug('Download report %s successfully! %s' % (order_id, msg or ''))
            failure = 0
        else:
            logger.debug('Download report %s failed with error %s!' % (order_id, msg or ''))
            failure += 1

        if failure >= 1000:
            logger.error('Found %d continuous download errors!' % failure)
            break

        # idx += 1
        idx -= 1

```

因为需要考虑到一种错误，因为当时在排队检查的时候，每一个样本最后都会被贴上一个编号，这个编号就是最终生成报告的编号，因为检测人员的操作可能存在的失误，会让有一些编号失效，这些号码会被弃用。猜测还有可能有些编号的纸张因为其他原因丢失或者弃用的原因，所以判定不会出现1000个以上的无效号码，如果出现了，那么往前/后的方向更远的编号应该也不会是有效的。

#### 分析报告

按照上面的规则，目前我拿到的16000+份有效的PDF报告，每个文件几乎都是392k，内容基本都是一样的，除了姓名和一个简单的结果会有所不同。同样的结果如果返回的JSON的话，一定会给我省很多的磁盘空间，*都怪我没有在他们做系统设计的时候提需求，否则也不会出这种冗余数据的笑话！*

老老实实解析PDF内容吧，这类方法很多，有不少开源的PDF解析库，这次我直接用了在SO上发现的一个基于Python的苹果`Foundation` framework的解法。

```python
def parse_result_from_pdf(filename):
    'Inspired by https://apple.stackexchange.com/a/352539/148516'
    username, result = None, None

    pdfURL = NSURL.fileURLWithPath_(filename)
    pdfDoc = PDFDocument.alloc().initWithURL_(pdfURL)

    if not pdfDoc:
        return username, result

    pdfString = NSString.stringWithString_(pdfDoc.string())
    # logger.debug(pdfString)

    for line in pdfString.split('\n'):
        if u'姓 名' in line:
            username = line.split(':')[1].split(' ')[0]
        elif u'阴性' == line:
            result = False
        elif u'阳性' == line:
            result = True

    return username, result
```

性能比我想象得快，大概30~40ms，考虑到是基于Python调用的我还能接受。和解析pdf简历不同，这种结构高度统一的数据直接暴力按行遍历取结果就行了。接下来就是把之前下载到本地的PDF报告遍历一下做个统计就行了。终于到了我想看的数据部分了。

```python
def analyze():
    'Analyze the downloaded reports\' result.'
    health, total = 0, 0
    bad_list, unknown_list = [], []

    for root, dirs, files in os.walk(DIR, topdown=False):
        for name in files:
            if name.endswith('.pdf'):
                total += 1
                fullpath = os.path.join(root, name)
                username, result = parse_result_from_pdf(fullpath)
                logger.info('%s\t%s\t%s\t%s' % (str(total).ljust(6), (username or 'Unknown').ljust(8), u'😱😱😱' if result else u'😀', name))

                if result is True:
                    bad_list.append(name)
                elif result is False:
                    health += 1
                else:
                    unknown_list.append(name)

    logger.info('In total: \nGood: %d, Bad: %d, Unknown: %d' % (health, len(bad_list), len(unknown_list)))

    if len(bad_list) > 0:
        logger.info('Bad list: %s' % (', '.join(bad_list)))

    if len(unknown_list) > 0:
        logger.info('Unknown list: %s' % (', '.join(unknown_list)))
```

输出很无聊，就不贴出来了，最后的统计结果是这样的：

```shell
21:17:34 - __main__ - INFO - In total:
Good: 16098, Bad: 0, Unknown: 1
21:17:34 - __main__ - INFO - Unknown list: XXXFFF100000.pdf
```

没有一个感染的，全部都合格，那个Unknown的结果后面单独查了一下是一个无效PDF的问题。老实说从数据上看第一眼我有点儿震惊，想了想也挺正常，挺庆幸的。至少一定程度上证明目前公司层面上没有瞒报的问题，所有人都健康。截止到这里，这是我爬这段数据的原本初衷。

不过话说回来，那些家伙居然没有把身份证号和手机号录到PDF里面，除了一个姓名和结果之外就什么有用的信息都没有，这个层面上我真的有点儿失望，什么福利都没有，白忙活了。

#### 总结

这个机构在首页号称是“助力新冠疫情后期湖北省产前筛查计划”的，还在这次北京疫情中拿到了新冠病毒核酸检测资质。要说他们泄露了公众隐私，从目前结果上看也没有那么夸张，要说他们没有泄露隐私，他们泄露了自己实验结果本身和对应的少量用户信息。

点名了，机构名称叫**北京安诺优达医学检验实验室有限公司**。

