---
layout: page
title: Prefer Status Bar on iOS
description: “"
image:
  path: http://example.jpg
  feature: status-bar-in-non-notch-iphone.png
  credit:
  creditlink:
tags: [iOS, uikit, status-bar, navigation-bar, coding]
comments: true
reading_time: true
modified: 2021-01-26

---

#### 历史

苹果在UIKit中提供了两套关于状态栏控制的API，一套是自iOS 2.0就有的基于`UIApplication`层面的全局控制：

```objective-c
@property(readwrite, nonatomic) UIStatusBarStyle statusBarStyle;
@property(readwrite, nonatomic,getter=isStatusBarHidden) BOOL statusBarHidden;

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle animated:(BOOL)animated;
- (void)setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation;
```

从废弃的另一部分API来看，早期甚至还可以通过手动控制屏幕旋转时候的状态栏状态。当然这些API自iOS 9开始被废弃了，但是直到iOS 14上面的API还能起作用，大概是苹果统计了很多App还在用这些API吧。

从iOS 7开始，基于`UIViewController`的新状态栏API替代品来了：

```swift
open var preferredStatusBarStyle: UIStatusBarStyle { get }
open var prefersStatusBarHidden: Bool { get }
open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { get }
open func setNeedsStatusBarAppearanceUpdate()
```



#### 对比

老版API必须通过`UIApplication`调用，全局只有一个app对象，所以控制状态栏的状态就完全基于代码的执行流程，立即生效，跟View Controller的生命周期完全无关，调用者理论上可以在任何一处通过全局application来改变状态栏的状态，**这很容易失控**。

从iOS 7开始，状态栏开始变成了页面设计的一部分，状态栏的状态应该跟随 view controller 的生命周期和具体的业务逻辑来变化。新版API完全是基于`UIViewController`生命周期的被动触发，我们很难知道系统是基于什么规则来判定**是否需要更新状态栏状态**，甚至去追溯这部分更新的逻辑在iOS各个版本中的差异。单纯简单地从API定义来看，只需要让每一个 view controller 各自维护好*当前的*状态栏状态就好。



#### 适配

对于一个新项目，新API的适配并不是一件很容易的事情，总体上需要理清项目中的页面结构，尤其是 container view controller。

* 确认App启动时的状态

  ```xml
  <key>UIStatusBarHidden</key>
  <true/>
  ```

  默认是显示的，hidden = false。

* 状态栏是否应该跟随 view controller 的生命周期而发生变化

  ```xml
  <key>UIViewControllerBasedStatusBarAppearance</key>
  <true/>
  ```

  默认是true，可以不用显式定义。但是当它是true的时候，再去通过`UIApplication`改变状态栏状态就是无效的了。这个很好理解，如果两套API同时有效，那场面一定会非常混乱。

* `UIViewController`的子类

  ```swift
  open var preferredStatusBarStyle: UIStatusBarStyle { get }
  open var prefersStatusBarHidden: Bool { get }
  open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { get }
  ```

  重写对应的方法即可，需要说明的是`preferredStatusBarUpdateAnimation`在*一般情况下*是不会触发的，只能在结合下文的`setNeedsStatusBarAppearanceUpdate`才会被调用。

* Container View Controller

  ```swift
  open var childForStatusBarStyle: UIViewController? { get }
  open var childForStatusBarHidden: UIViewController? { get }
  ```

  当某一个 view controller 有需要根据其中某一个 subview controller 的状态来判定全局状态栏状态的时候，需要重写这两个方法并返回对应的 subview controller。如果不存在，return nil，当前 view controller 的preferred***状态会被作为最终结果被全局状态栏使用。这种 container controller 有几种情况：

  * Custom Container View Controller

    它可以是自定义的TabBarController，也可以是自定义的NavigationController，甚至可以是某一个复杂页面。这个时候就完全需要我们手动重写继承自`UIViewController`的这几个方法了。

  * `UITabBarController`

    好消息！这里什么都不用做，因为`UITabBarController`已经**猜**到我们想要做什么了。

  * `UINavigationController`

    由于navigation controller维护了一个view controller的堆栈，它还支持`push`和`show`等多种不同的页面呈现管理方式，`UINavigationController`并不是太好判定我们的业务层具体会使用什么样的页面逻辑，所以需要我们手动重写上面的 childForStatusBar*** 方法。

    * push
    * show


* Present Modal View Controller

  对于 presenting view controller 来说，如果不是全屏呈现的，默认情况下状态栏是隐藏的，可以打开 `modalPresentationCapturesStatusBarAppearance` 来允许重载。对于全屏显示的 view controller 来说，可以直接重载。



#### Call Routes

为了验证新API的效果以及它是如何起作用的，这里我单独构建了一个demo来验证。页面结构大体是这样的：

```
keyWindow
└── TabBarController(rootViewController)
    └── NavigationController
        ├── FirstViewController(rootViewController)
        ├── SecondViewController
        └── ThirdViewController
```

当app启动的时候：

```
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <FirstViewController: 0x7f9b68809fd0>
viewDidLoad(): <FirstViewController: 0x7f9b68809fd0>
viewWillAppear(_:): <FirstViewController: 0x7f9b68809fd0>: true
navigationController(_:willShow:animated:):<FirstViewController: 0x7f9b68809fd0>
navigationController(_:didShow:animated:):<FirstViewController: 0x7f9b68809fd0>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <FirstViewController: 0x7f9b68809fd0>
viewDidAppear(_:): <FirstViewController: 0x7f9b68809fd0>: true
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <FirstViewController: 0x7f9b68809fd0>
```

从 `FirstViewController` push 到 `SecondViewController` 的时候：

```
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <FirstViewController: 0x7f9b68809fd0>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
viewDidLoad(): <SecondViewController: 0x7f9b6661c700>
viewWillDisappear(_:): <FirstViewController: 0x7f9b68809fd0>: true
viewWillAppear(_:): <SecondViewController: 0x7f9b6661c700>: true
navigationController(_:willShow:animated:):<SecondViewController: 0x7f9b6661c700>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
viewDidDisappear(_:): <FirstViewController: 0x7f9b68809fd0>: true
viewDidAppear(_:): <SecondViewController: 0x7f9b6661c700>: true
navigationController(_:didShow:animated:):<SecondViewController: 0x7f9b6661c700>
childForStatusBarHidden: <TabBarController: 0x7f9b68019800>
childForStatusBarHidden: <NavigationController: 0x7f9b66829200>
prefersStatusBarHidden: <SecondViewController: 0x7f9b6661c700>
```

可以看到当系统认为状态栏**有可能需要发生状态改变的时候**都会开始从`rootViewController`开始重新遍历*我们期望的 topViewController*，并没有在系统内部某处保存当前的 *topViewController* 然后下次重用，猜测还是因为 custom container view controller 可以实现很多种不同的页面结构（包括实现基于`UIView`的 view controller？）。从结果上看它更像是系统事件的 `hitTest` 调用过程，至于次数和时机就不能无从考证了，有时候点击 `viewcontroller.view` 都可以触发好几次调用。



#### Animation

`preferredStatusBarUpdateAnimation` 一般情况下是不会被调用的，直到 `setNeedsStatusBarAppearanceUpdate` 被手动调用，它为业务层面提供了一个手动更新入口来更新状态栏的状态。动画效果种类不多，但是时长却可以控制。

```swift
UIView.animate(withDuration: 1) {
    self.setNeedsStatusBarAppearanceUpdate()
}
```



#### Landscape

状态栏在横屏模式下是不显示的， 不管是通过哪一版API强制指定显示也无效，看起来是苹果更新了这部分逻辑还是bug，**测试环境是iOS 13/14 & iPhone 8/SE/11**，*但是从Stack Overflow的搜索答案上来看老版本应该是可以做到的，只是不明确各自测试的具体系统版本号*。



#### Bug

有意思的 bug 来了，在 **iOS 13 & 14 的非全面屏设备**中，`UINavigationController ` 的导航栏的状态栏会有重叠的现象，不管是新旧两个版本的API都会有这个问题。如果尝试从初始的竖屏切换到横屏状态再切回到竖屏状态之后，重叠问题*解决了*。我尝试了所有可能跟 `UINavigationBar` 和 `UIStatusBar` 相关的 public methods 都不能解决这个问题，`UIViewController`在这方面也并没有暴露太多的相关的信息。直到尝试重载一个 `UINavigationBar` 的 `frame` setter 并输出相关堆栈，最后发现一个关键的私有方法 `_updateLayoutForStatusBarAndInterfaceOrientation`。手动调用它之后立刻解决了重叠问题，在 [iOS Runtime Headers](https://github.com/nst/iOS-Runtime-Headers) 发现很多种系统自带的 container view controller 都实现这个私有方法，但是苹果并没有暴露出来一个 public 版本给我们。

```bash
➜  iOS-Runtime-Headers git:(master) rg "updateLayoutForStatusBarAndInter" .
./protocols/UISplitViewControllerImpl.h
42:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/SpringBoardUI.framework/SBUISlidingFullscreenAlertController.h
21:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UIViewController.h
897:- (bool)_shouldUpdateLayoutForStatusBarAndInterfaceOrientation;
947:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UINavigationController.h
526:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UISplitViewControllerClassicImpl.h
264:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UITabBarController.h
164:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UIMultiColumnViewController.h
72:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UISplitViewController.h
99:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UISplitViewControllerPanelImpl.h
157:- (void)_updateLayoutForStatusBarAndInterfaceOrientation;

./PrivateFrameworks/UIKitCore.framework/UIPresentationController.h
27:bool  _didUpdateLayoutForStatusBarAndInterfaceOrientation;
```

无独有偶，Telegram for iPad 也出现了这个 [bug](](https://github.com/TelegramMessenger/Telegram-iOS/issues/240)) ，直到现在的最新版（7.3）还是没有解决。在早年的 iOS 版本中看起来也出现过这个问题，比如[这个](https://openradar.appspot.com/9351530)，[这个](https://openradar.appspot.com/39434142)，还有[这个](https://openradar.appspot.com/14201871)。

不管是横屏效果还是重叠问题，只有在 iOS 11 & 12 中表现完美，所以这应该是自 iOS 13 开始就一直存在的 bug。状态栏的控制是一个可轻可重的问题，印象中以前适配过新API但是没有特别在意这方面的细节，印象不深。Stack Overflow上目前的相关的解决办法还都是以废弃的 `UIApplication` 为主的，但仍然在 iOS 14 中表现不好。不管是 iOS 的 bug 还是想找到真正合适的解决方案，我已经向苹果提交了一个技术支持（DTS），希望能得到官方的解决方式。

##### Solution

1. 在每一个相关的 view controller’s `viewWillAppear` 中调用

   ```swift
   let sel = NSSelectorFromString("_updateLayoutForStatusBarAndInterfaceOrientation")
   
   if let result = navigationController?.responds(to: sel), result {
       navigationController?.perform(sel)
   }
   ```

   也可以写在`UINavigationControllerDelegate` `navigationController(_:willShow:animated:))`里面。私有方法调用有风险，没有测试过是否能够审核通过。

2. 手动修正 `UINavigationBar` 的 frame 问题，在相关 view controller’s `viewWillAppear` 中调用：

   ```swift
   guard let naviVC = navigationController else {
       return
   }
   
   let statusBarFrame = UIApplication.shared.statusBarFrame
   let naviBarFrame = naviVC.navigationBar.frame
   
   naviVC.navigationBar.frame = CGRect(x: naviBarFrame.origin.x, y: statusBarFrame.maxY, width: naviBarFrame.width, height: naviBarFrame.height)
   ```

   略显生硬，但是效果直接，在 `largeTitle` 模式下也没有问题。但是如果未来苹果再加一个 extended large title mode 或者直接把导航栏移到屏幕下方了（？？？），那时候记得重新适配（适配不是常态吗？）。

至于横屏状态栏的问题，确认只是从 iOS 13 开始不可控，只能隐藏。



#### UIApplication

本质上状态栏仍然是一个全局的存在，为什么苹果要把它从 `UIApplication` 这个单例中移除呢？从 App extension, multiple windows 等功能上来看，猜测苹果不希望未来各类功能都往 `UIApplication` 里面放，必须强制归类新概念，弱化单例的功能，不能让 `UIApplication` 变成一个不可收拾的垃圾桶。