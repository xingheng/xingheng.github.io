---
layout: page
title: Objective-C with MVVM on iOS
description: null
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink:
tags: [objective-c, mvvm, iOS, UIKit, architecture, coding]
comments: true
reading_time: true
modified: 2022-07-02
---



> Review the MVVM pattern with Objective-C on iOS development again.



## Preface

In [the last post](https://xingheng.github.io/objective-c-with-mvc-on-ios/) I’ve proven what the view model it is and how to use it correctly in mvc pattern, it can recall me about another famous architectural pattern [MVVM](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) (Model-View-ViewModel) always. However, they are two different patterns totally, I also mentioned the key point is the binding technology. So what on earth is it and how does it work? Let’s split it into piece.



## MVVM Overview

Let’s check the diagram out from [wikipedia](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller), the relationship between view and view model is *data binding*, sometimes this pattern is also called MVB (Model-View-Binding), so we could realize that how important the binder is here.

<img src="https://upload.wikimedia.org/wikipedia/commons/8/87/MVVMPattern.png" style="display:block;margin-left:auto;margin-right:auto;width:50%"/>

We never hear about this magic technology said by Apple before, for the iOS developers, the most correlative things is likely KVO and `NSNotificationCenter`, but they are not the same. Imagine that there is a text element presenting in UI, when updating a property of a special model with a new content, the text element’s content get changes in the same time, too. Fantastic, right? Actually, windows developers working on ASP.NET and WPF use this builtin feature all the time, that’s [XAML](https://en.wikipedia.org/wiki/XAML) we’ve mentioned before. Apple didn’t do it for iOS UIKit ever.

> Notes: There is another declarative framework for Swift called [Combine](https://developer.apple.com/documentation/combine) which is designed for SwiftUI.

So how to introduce this incredible feature to objective-c or swift language for iOS platform? That’s [ReactiveCocoa](https://github.com/reactivecocoa/reactivecocoa), a famous library implemented [Rx](https://reactivex.io/) for Cocoa framework.



## Binder

I won’t cover what the reactive framework it is or how to use it in our projects, there are a lot of alternative frameworks built for iOS, for example,

* [RxSwift](https://github.com/ReactiveX/RxSwift)
* [OpenCombine](https://github.com/OpenCombine/OpenCombine)

They have their own historical story in its evolution, you (the reader) could find their pros and cons in different aspects. No recommendation here.



## ViewModel

Yes, the view model is still the key subject and I will show something wrong I saw in the past team projects before.

1. Using RAC doesn’t mean MVVM pattern.

   Some projects introduce RAC library as project dependency but no explicit view model object built, they just create and subscribe signals for views and models, all of those binding code happen in controllers (`UIViewController` subclass’s implementation). 

   It works but losing one of the most important feature of MVVM: easy for testing. The massive controller implementation didn’t be resolved, more important, debugging those massive controllers is out of control.

2. Use RAC for business models instead.

   The binder is designed for view components in MVVM, but RAC didn’t limit which objects we should use in, then here it is, it uses RAC to bind the business model to view model only and  update the view objects manually in the corresponding controller.

   This works, too, for a simple one-way binding page, but it doesn’t take full advantages of RAC for view objects.

3. Missing RAC interface for custom views.

   RAC framework has make the basic signal methods for those builtin views from UIKit, so why not exposing the additional signal interfaces for custom view class by design? When migrating from MVC to MVVM, it’s important to get the point of signal which will happen anywhere.

4. Use two-way binding heavily.

   Most of time one-way binding is enough for us to implement a lot of features, using two-way binding heavily will make the debugging progress hard to control.

I didn’t write a relevant sample project to describe what the correct MVVM is, there are a lot of good samples already, [C-41](https://github.com/AshFurrow/C-41) is one of the good case.



## Conclusion

MVVM brings a totally different design from MVC, it’s not a good idea to make transition from MVC to MVVM in half-way, they are not compatible each other. Keep in mind that view model is the core bridge interface for view component always and use the binder as possible as we can.
