---
layout: page
title: Header Practice - Part 2
description:
image:
  path: http://example.jpg
  feature:
  credit:
  creditlink:
tags: [objective-c, iOS, coding]
comments: true
reading_time: true
modified: 2021-08-29
---

```
#import "UserHeader.h"
```



#### Story

[上一篇](https://xingheng.github.io/header-practice-part1/)我们已经试验了一番头文件的引用和编译时长的关系，但是好像和我们的实际项目没多大关系，或者关系不大？想想好像没人会一股脑地往 prefix header 里面塞一堆的头文件引用，不一定，这个得结合实际看结果。

基于之前的结论，一个普通的 header 被引用到 prefix header 里了之后，被*引用的内容* 就已经是 prefix header 的内容了。要想看到我们 Xcode 项目里面真实的 prefix header 长什么样子，还得从头展开。首先从目标 target 的 `Build Setting` - `Prefix Header` 设置中找到目标文件，然后逐行浏览，如果碰到一个 `#import` ，就立刻把该文件的内容提取出来，然后继续深度迭代….直到解析完 prefix header 文件中所有的行为止。想想好像挺无聊的，平时只是在 IDE 里面专注写代码，好像并没有想过这个问题。

祭出分析工具：[code-analyzer](https://github.com/xingheng/code-analyzer)，以前尝试写的基于 Objective-C 分析简单的代码优化，基于它我又加了一个新的简单功能：首先遍历出所有的目标头文件，然后通过指定的头文件入口检索并绘制出了一棵引用树。其中会屏蔽掉第三方库 CocoaPods 里面导入的头文件等等，至于为什么要屏蔽掉这部分最后面会说明。

```bash
python main.py generate-header-graph <project-path> <entry-header-file> [--dot-file project-header-tree.dot]
```



#### Hunting Time

坦白说，我司的项目是有这个问题的，但是不能在这里暴露任何符号相关的安全问题。只好拿开源的项目当教材了，在 github 上搜索了一圈的关于 prefix header 的大量使用的案例（pch 后缀可以认为是 Xcode 项目独有的），发现并没有我想要的结果（开源项目真优秀~）。转到以前 clone 到本地过的项目倒是发现了惊喜，下面会曝光几个。

首先是 [WeChatExtension-ForMac](https://github.com/MustangYM/WeChatExtension-ForMac)，看起来还好，大部分都是非业务层的 category，我觉得可以接受。

```bash
python main.py generate-header-graph ./WeChatExtension-ForMac ./WeChatExtension-ForMac/WeChatExtension/WeChatExtension/Sources/Common/YMPrefixHeader.pch
YMPrefixHeader.pch
    ColorConstant.h
    DefineConstant.h
        YMWeChatPluginConfig.h
            GVUserDefaults.h
            WeChatPlugin.h
    NotifyConstant.h
    NSView+Action.h
    NSButton+Action.h
    NSTextField+Action.h
    NSMenu+Action.h
    NSString+Action.h
    NSDate+Action.h
    NSWindowController+Action.h
    WeChatPlugin.h
    YMDeviceHelper.h
    YMWeChatPluginConfig.h
    YMSwizzledHelper.h
```

再看一个 [appledoc](https://github.com/tomaz/appledoc)，这个就更没话说了，让 DDLog 在全局可见也是我们的常见操作。

```bash
python main.py generate-header-graph ./appledoc ./appledoc/appledoc_Prefix.pch
appledoc_Prefix.pch
    NSObject+GBObject.h
    NSString+GBString.h
    NSArray+GBArray.h
    NSException+GBException.h
    NSError+GBError.h
    NSFileManager+GBFileManager.h
    GBLog.h
        DDLog.h
            DDLog.h
        DDTTYLogger.h
            DDLog.h
        DDFileLogger.h
            DDLog.h
        DDCliUtil.h
    GBExitCodes.h
```

最后再曝一个有意思的，这是某宁曾经遭泄露的客户端代码，发现它的时候我也很惊讶。（真的不是我故意选这个的，`find . -type f -name "*.pch" | xargs -I{} grep -sinr "#import \"" {}`，匹配行数首屈一指。）

```bash
python main.py generate-header-graph ./NewEBuy-master  ./NewEBuy-master/sourceCode/SuningEBuy/Prefix.pch --dot-file ~/Desktop/test/newebuy.dot
Prefix.pch
    Constant.h
        AppConstant.h
        HttpConstant.h
            SuningEBuyConfig.h
        NotificationConstant.h
        DefineConstant.h
        TableConstant.h
        PathConstant.h
        MsgConstant.h
        ResourceConstant.h
        EnumConstant.h
    SNLogger.h
    Config.h
    SNUITableView.h
    SNUITableViewCell.h
    SNUIBarButtonItem.h
    SNUIAlertView.h
    SNUIActionSheet.h
    SNUILabel.h
    SNUITextField.h
    SNUIWebView.h
    SNUIButton.h
    SNUITextView.h
    SNUIView.h
    SNUIImageView.h
    SNUIScrollView.h
    SNUISearchBar.h
    SNUIPageControl.h
    BBAlertView.h
    SNBarButtonItem.h
    ASIHTTPRequest.h
        ASIHTTPRequestConfig.h
        ASIHTTPRequestDelegate.h
        ASIProgressDelegate.h
        ASICacheDelegate.h
    ASIFormDataRequest.h
        ASIHTTPRequest.h
        ASIHTTPRequestConfig.h
    NSObject+JSON.h
    Http.h
    Additions.h
        NSString+Additions.h
        NSString+MD5.h
        NSString+NULL.h
        NSString+SEL.h
        UIView+Additions.h
        UIView+Appear.h
        UIView+Draw.h
        UIView+firstResponder.h
        UIView+RoundedCorners.h
        UIColor+Helper.h
        UIColor-Expanded.h
        UIColor-HSVAdditions.h
            UIColor-Expanded.h
        UIImage-Extensions.h
        NSDate+Helper.h
        UIBarButtonItem+Additions.h
        NSNumber+Additions.h
    CommonViewController.h
        UIView+ActivityIndicator.h
            MBProgressHUD.h
            LoadingHUDView.h
            ToolTipView.h
            BBTipView.h
        AppDelegate.h
            TabBarController.h
            WXApi.h
                WXApiObject.h
            DMOrderDTO.h
                BaseHttpDTO.h
                    HttpConstant.h
            ScreenShotView.h
        BBTipView.h
        BBAlertView.h
        NSTimerHelper.h
        SuningMainClick.h
            GetAllSysInfo.h
                InformetionCollectDTO.h
                Preferences.h
                AppDelegate.h
                SaveSuningUUID.h
            InformetionCollectDTO.h
            InformationCollectDAO.h
                DAO.h
                InformetionCollectDTO.h
            SuningPageObject.h
                UIViewController+SNRouter.h
                    SNRouterObject.h
            UIViewController+SuningClick.h
                SuningPageObject.h
        SNNetworkErrorView.h
        BottomNavBar.h
        SNRouter.h
            SNRouterObject.h
            UIViewController+SNRouter.h
        SSAIOSSNDataCollection.h
        PerformanceStatistics.h
        AnalyzeViewController.h
            HttpMsgCtrl.h
                HttpMessage.h
                    MsgConstant.h
                    ASIHTTPRequest.h
                Command.h
                CommandManage.h
                    Command.h
    AuthManagerNavViewController.h
        ScreenShotNavViewController.h
    UserCenter.h
        UserInfoDTO.h
            AddressInfoDTO.h
                BaseHttpDTO.h
            BaseHttpDTO.h
        IPInfoDTO.h
            BaseHttpDTO.h
        UserDiscountInfoDTO.h
        UserLoginService.h
            DataService.h
                HttpMessage.h
                HttpMsgCtrl.h
            UserInfoDTO.h
            PasswdUtil.h
    GlobalDataCenter.h
    NSObject+BoardManage.h
    CommandManage.h
    DefaultKeyWordManager.h
    NSDictionary+Additions.h
```

> 把这个结果绘制成了一张 graphviz 图，传到了[这里](https://i.imgur.com/D5Te5pC.png)。

这个结果就是我认为的反面教材了，大量的业务层代码混入，只要其中一个头文件发生了变动，整个项目就必须重现编译。



#### Solution

这些 `#import` 理论上是可以避免的，因为有些项目都没有直接用 prefix header，让所有的头文件的地位平等，谁需要 `<CloudKit/CloudKit.h>` 就直接在当前源文件里引用，优先考虑放在 `.m` 文件里面，如果在 `.h`文件里有链接的必要，就放在 `.h` 文件里，毕竟当前的 `.h` 还是会被其他源文件引用的。从最开始就严格控制 `#import`，这其实就是最自然最理想的头文件引用管理，没什么花里胡哨的。

当一个项目越做越大的时候，放在 `.m` 里面的头文件 `#import` 数量会跟着增加，可能同一个功能存在的两个 `A1.m` 和 `A2.m` 都存在着大量相同的引用，这个时候可以考虑**直接创建一个新的独立的 Header File** 来存储那些已经产生交集的 `#import` 集合，如果有相同或者类似的功能的源文件产生时就可以直接引用已经存在的独立头文件了。当然，即使已经有了独立的存在的这些头文件，**新的源文件在被创建时候的时候始终应该优先考虑只 import 自己需要的 header**。这样头文件引发的灾难才不会一发不可收拾。

如果类似某宁的头文件灾难已经产生，可以考虑倒置这个的引用原则，先把 prefix header 里面的内容或者基于业务分类，或者基于MVC层级来拆解，创建独立的 header files 把他们归类，最终把分类好的头文件从 prefix header 的结构中拆分出来，不断靠齐，按需编译。

并不是要否定 prefix header 的意义，它能在一定程度上解决在源文件节点中大量重复的引用，但它不是我们定义 或者引入符号的地方。允许把一些最核心的系统库或者部分三方库引用到 prefix header 里来表明它的地位和用途，因为这一类头文件所在库在日常开发过程中几乎不会有更新，也就是说不会有任何改动，自然也不会引起业务层所有源文件的重编译。当然，能放在分组的独立头文件中自然最好。

Prefix header 不是垃圾桶，小心嵌套引用。

> 从编译器的角度上来看这个点，做好了理所当然，做不好就是垃圾。

