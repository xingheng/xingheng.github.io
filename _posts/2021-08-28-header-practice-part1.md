---
layout: page
title: Header Practice - Part 1
description:
image:
  path: http://example.jpg
  feature:
  credit:
  creditlink:
tags: [objective-c, iOS, coding]
comments: true
reading_time: true
modified: 2021-08-28
---

```
#import <UIKit.h>
```



Objective-C 在项目中离不开头文件，它是最基本的控制对象访问权限的直观形式，相当于给一个 Swift 类型定义最重要的访问权限。不能说不重要，一个类型的设计在被应用之前最重要的一步。以前也做过头文件相关的优化，原理和实践都是看起来很简单，但是还没有实实在在的测试过头文件的优化在一个大项目中的具体分量，尤其是 prefix header（预编译头文件）。



#### Prefix Header

> A **prefix header** is a feature found in some [C](https://en.wikipedia.org/wiki/C_(programming_language)) or [C++](https://en.wikipedia.org/wiki/C%2B%2B) [compilers](https://en.wikipedia.org/wiki/Compilers) used to ensure that a certain snippet of code is inserted at the beginning of every file.

[Prefix header](https://en.wikipedia.org/wiki/Prefix_header) 原本的意义是让编译器编译得更快，把相同的文件引用和代码块放在一起组成一个代码块，放在 prefix header 里面只要编译一次就会被缓存，这样相同的代码块在其他源文件在被编译得时候就不需要重复编译了，*除非内容有更新*。好玩的地方来了，到底什么样的动作才算更新呢？更新导致的重复编译的代价到底有多大呢？实验一下就知道了。



#### Environments

* MacBook Pro 2020, 2 GHz Quad-Core Intel Core i5, 16 GB 3733 MHz LPDDR4X
* macOS 11.4 (20F71)
* Xcode 12.5 (12E262)

项目地址：[HeaderPractice](https://github.com/xingheng/HeaderPractice) 



#### Test Cases

我们分别编译一个空项目，带1000个模拟源文件的项目，启用 prefix header 以及 prefix header 中导入其他叶子节点头文件的项目中做对比实验。

> *clean build*: 描述的是相当于在 Xcode 中执行了 *Product* -> *Clean* 以清除先前的 build folder 之后再执行编译操作。
>
> *build with cache*: 描述的是之前已经基于当前的绝大部分源文件内容编译成功了的再次编译。
>
> *平均时长*: 描述的是当前上下文中的操作是在执行了多次之后根据每次的总时长算出来的每次操作执行的总时间时长，单位是秒(s)。如果是时间段格式，意思是多次执行之后的最短-最长时长。
>
> *asciinema 动画渲染*：我开启了最长2秒不活跃重放，所以从动画录制总时间上看起来和实际的开始停止时长可能不一致，这只是为了观看效果而已。（`idle_time_limit = 2`）
>
> *just*: 一个命令封装[工具](https://github.com/casey/just)，项目中使用的所有命令都已经封装到了 justfile 中。

* **Case1**: 只编译空项目

  * **Case 1-1**: clean build

    平均时长：2-3s

    因为只有三个源文件，`main.m`, `AppDelegate.m`, `MainViewController.m`, 所以总时间肯定肯定不会太慢。编译出来的二进制也只有75K。

  * **Case 1-2**: build with cache

    平均时长：1-2s

    在不清理 Build 缓存的情况下，总时长只快一半左右。因为源文件数据太少的原因，这里还不能看出来编译每个文件的平均时间大概在什么范围内。

  头文件为空，预编译 `MainViewController.m`：

  ```objc
  # 1 "/Users/me/Documents/Projects/gitRepository/HeaderPractice/HeaderPractice/MainViewController.m"
  # 1 "<built-in>" 1
  # 1 "<built-in>" 3
  # 380 "<built-in>" 3
  # 1 "<command line>" 1
  # 1 "<built-in>" 2
  # 1 "/Users/me/Documents/Projects/gitRepository/HeaderPractice/HeaderPractice/PrefixHeader.pch" 1
  # 2 "<built-in>" 2
  # 1 "/Users/me/Documents/Projects/gitRepository/HeaderPractice/HeaderPractice/MainViewController.m" 2
  
  # 1 "/Users/me/Documents/Projects/gitRepository/HeaderPractice/HeaderPractice/MainViewController.h" 1
  
  #pragma clang module import UIKit /* clang -E: implicit import for #import <UIKit/UIKit.h> */
  
  #pragma clang assume_nonnull begin
  
  @interface MainViewController : UIViewController
  
  @end
  #pragma clang assume_nonnull end
  # 9 "/Users/me/Documents/Projects/gitRepository/HeaderPractice/HeaderPractice/MainViewController.m" 2
  
  @interface MainViewController ()
  
  @end
  
  @implementation MainViewController
  
  - (void)viewDidLoad {
      [super viewDidLoad];
      // Removed some unrelated source code...
  }
  
  @end
  ```

* **Case 2**: 加入1000个源文件

  为了模拟头文件引用在真实项目里面的编译情况，我们直接生成1000个源文件来测试，文件内容也很简单，只是单纯定义了一个 placeholder 类而已：

  ```objc
  //
  //  Placeholder1.h
  //  HeaderPractice
  //
  //  Created by WeiHan on 2021/8/26.
  //
  
  #import <Foundation/Foundation.h>
  
  NS_ASSUME_NONNULL_BEGIN
  
  @interface Placeholder1 : NSObject
  
  @property (nonatomic, strong) NSString *title;
  @property (nonatomic, assign) NSUInteger value;
  @property (nonatomic, assign) BOOL state;
  
  @end
  
  NS_ASSUME_NONNULL_END
  ```

  ```objc
  //
  //  Placeholder1.m
  //  HeaderPractice
  //
  //  Created by WeiHan on 2021/8/26.
  //
  
  #import "Placeholder1.h"
  
  @implementation Placeholder1
  
  @end
  ```

  然后重复创建，把他们加入到项目中，开始编译。这个时候因为类符号的增加让输出的二进制瞬间增长到了3.1M。

  > 参照脚本 generator.sh，通过 just 执行：`just generate-files 1000`。加入到 HeaderPractice.xcodeproj 中，`just generate-files-project`。开始编译：`just build`。

  * **Case 2-1**: clean build

    平均时长：第一次 44s，第二次 36.2s

    <script src="https://asciinema.org/a/14.js" data-preload="false" id="asciicast-432625" async></script>

  * **Case 2-2**: build with cache

    平均时长：2.2s

* **Case 3**: 修改 prefix header，增加了一行 import。

  * **Case 3-1**: build with existing cache

    <script src="https://asciinema.org/a/14.js" data-preload="false" id="asciicast-432631" async></script>

    总时长：31s。

    继续修改，不断增加一个新的 inline function然后重新编译，总时长都在27~31s之间。这个地方有意思的是即使什么都不改，直接保存再编译 `xcodebuild` 也会重新编译所有源文件。我尝试在编译过程中去修改 prefix header 的内容甚至会直接报错：

    ```
    ❌  fatal error: file '/Users/me/Documents/Projects/gitRepository/HeaderPractice/HeaderPractice/PrefixHeader.pch' has been modified since the precompiled header '/Users/me/Library/Developer/Xcode/DerivedData/Build/Intermediates.noindex/PrecompiledHeaders/SharedPrecompiledHeaders/1005249678327501540/PrefixHeader.pch.gch' was built: mtime changed
    ```

    原来是以 `mtime` 的结果为准的，那就不需要我再继续动脑子想办法每次手动编辑 prefix header 了，直接 `touch` 好了。

    从执行日志和结果上来说，只有 prefix header 文件发生了变化就会编译所有源文件。

  * **Case 3-2**: clean build

    保留上一步所有的 prefix header 中新增的 import 和 inline functions，继续连续编译10次。
    
    平均时间36.6s。和 *Case 2-1* 中的结果相差不大。

* **Case 4**: 修改prefix header，import 一堆的[系统头文件](https://gist.github.com/xingheng/d7b6c3625b89f90608fc0b93c08e0631)试试。

  这相当于给每一个源文件都新增了这些头文件的引入，*Case 2* 中的源文件虽然多但是内容是空的，和实际项目场景相差很远。引入头文件之后每一个源文件的大小就更接近与实际项目的环境了。
  

  * **Case 4-1**: touch, build with cache
  
    在每次 build 之前先 `touch` 一下 prefix header 之后重新编译（没有 clean）的结果。
  
    平均时长98.4s。
  
  * **Case 4-2**: clean build
  
    什么都不改，只是 `clean build`。
  
    平均时长100s。
  
  * **Case 4-3**: build with cache only
  
    执行10次 build。
  
    时长都在2~3s。
  
  结论：
  
  1. prefix header 变化了之后的过程相当于 clean build。
  2. 在不 clean build 的情况下，编译一个只有3个文件的项目和编译1000个文件的项目耗时几乎是一样的。说明 `xcodebuild` 在解析项目结构并检查 module cache 的总时间也就在这3秒内。
  
  继续对 `MainViewController.m` 预编译看一下结果，和 *Case 1* 中的结果对比，主要是增加了所有系统头文件的 `#pragma` 编辑器指令，其他的并没有什么大的不同。
  
  ```objc
  #pragma clang module import Foundation /* clang -E: implicit import for #import <Foundation/Foundation.h> */
  #pragma clang module import UIKit /* clang -E: implicit import for #import <UIKit/UIKit.h> */
  ```
  
* **Case 5**: 修改 prefix header 中被引用的头文件内容试试。

  上面的 *Case 3* 我们已经确认了：当 prefix header 文件本身产生了修改操作就会让之前的缓存失效并重新编译所有文件。那么如果只改变 prefix header 中引用的其他文件的内容而不修改任何其他内容会怎么样呢？只是 touch 被引用的头文件呢？

  * **Case 5-1**: edit or touch, build with cache

    <script src="https://asciinema.org/a/14.js" data-preload="false" id="asciicast-432973" async></script>
    
    结果证明被引用到 prefix header 中的文件就相当于 prefix header 中的一部分，任何被引用的头文件的修改也会被定义为 prefix header 已经脏了，即需要重新编译整个项目的源文件。

* **Case 6**: 跳过 prefix header，让所有的源文件直接引用一个普通的头文件

  Prefix header 在定义的时候就直接被所有源文件引用的，在 Xcode 中它可能被做了一些特殊的处理，如果换成一个普通的头文件被引用的话会怎么样呢？

  * **Case 6-1**: replace the prefix header with common header

    我们在 `generator.sh` 里面创建 `PlaceholderX.h` 的文件里加一段 `import “CommonHeader.h" `，同时从 `PrefixHeader.h` 中删除 `import "CommonHeader.h"`，重新生成并编译。

    动画放在了下面的 *Case 6-2*。

    从结果上看 prefix header 和普通的 header没有什么区别，都会让被引用的所有源文件重新编译，即使只是 `touch` 了一下。

  * **Case 6-2**: import common header in a half of source files

    虽然已经能意料到了但是我们还是验证一下这个结果：只在上文中生成的1000个文件中选一半的文件进行对比。

    ```objc
    #if $id <= 500
    	#import "CommonHeader.h"
    #endif
    ```

    <script src="https://asciinema.org/a/14.js" data-preload="false" id="asciicast-432979" async></script>
    
    对比可以看到只是 `CommonHeader.h` 发生变化的话就只编译了一半的源文件，编译时间也减少了一半左右。



#### Conclusion

从上面所有对比测试中可以确认几个重要的点：

* 不管是 prefix header 还是普通的 header file，只要文件的修改时间 `mtime` 发生了改变就算是内容的变化。
* 一个普通的 header 被引用到了 prefix header 里面之后，这个文件就相当于是 prefix header 的一部分了。
* Prefix header 的改动会影响当前环境的所有源文件的重编译，但是普通的 header 可以*分流*，可以控制编译时长。

基于这个结论，[下一篇](https://xingheng.github.io/header-practice-part2/)我们再来分析怎样从头文件的角度优化项目的编译速度。

