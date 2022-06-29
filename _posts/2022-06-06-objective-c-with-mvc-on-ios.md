---
layout: page
title: Objective-C with MVC on iOS
description: null
image:
  path: http://example.jpg
  feature: 
  credit: 
  creditlink:
tags: [objective-c, mvc, iOS, UIKit, architecture, coding]
comments: true
reading_time: true
modified: 2022-06-06
---



> Review the MVC pattern with Objective-C on iOS development again.



## Preface

MVC(Model-View-Controller) architectural pattern is over 40 years old today and has been already used in so many iOS projects, it’s also the most usual pattern I saw in all kinds of team and company projects. There are also many new patterns which try to replace MVC to resolve the classic massive issue, some of them are nice and inspiring but didn’t be famous, I think there are many reasons in it. This post won’t cover all the differences or (dis)advantages among them, the main purpose here is trying to correct some wrong designs I saw before and resolve the massive issue in some aspects.



## MVC Overview

MVC is a vague pattern that every platform has its own explanation, there are many different descriptions for it after searching with keywords “mvc diagram”. Here we will focus the Apple/iOS platform only, the following diagram comes from [apple documentation](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/MVC.html).

<img src="https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/Art/model_view_controller_2x.png" />

> **Model**
>
> Model objects encapsulate the data specific to an application and define the logic and computation that manipulate and process that data.
>
> **View**
>
> A view object is an object in an application that users can see.
>
> **Controller**
>
> A controller object acts as an intermediary between one or more of an application’s view objects and one or more of its model objects.

We could see that there are no any communications between view and model objects, the view update’s task belongs to controller object. It feels so normal because the controller, `UIViewController` generally, retains all the view objects directly in it.

>  Notes: For programming with storyboard or xib UI files, it’s `UINib` who retains all the subviews directly, and the associated `UIViewController` as a file owner control them.

---

Let’s check another diagram out from [wikipedia](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller), the model updates the view components directly, this is exactly right as well, for ASP.Net web programming. View is built based on XAML files and accessible for models, the controller doesn’t retains the view components directly.

<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/a0/MVC-Process.svg/1000px-MVC-Process.svg.png" style="display:block;margin-left:auto;margin-right:auto;width:50%"/>

So, how to explain the *model component*‘s responsibility exactly in MVC? Let’s find one more document said by [microsoft](https://docs.microsoft.com/en-us/aspnet/core/mvc/overview?view=aspnetcore-6.0):

> The Model in an MVC application represents the state of the application and any business logic or operations that should be performed by it. Business logic should be encapsulated in the model, along with any implementation logic for persisting the state of the application. Strongly-typed views typically use ViewModel types designed to contain the data to display on that view. The controller creates and populates these ViewModel instances from the model.



## ViewModel

Here it comes! View model is separated from model definitions, it’s designed for view component to communicate with controller and differ from business models, we call it *ViewModel* instead of a common model component.

Actually, apple also [introduced](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/MVC.html#//apple_ref/doc/uid/TP40008195-CH32-SW1) the similar concept about its MVC:

> Ideally, a model object should have no explicit connection to the view objects that present its data and allow users to edit that data—it should not be concerned with user-interface and presentation issues.

A model shouldn’t be used in view’s implementation, the controller shouldn’t update the view data with pieces fundamental data in its own implementation, either. There must be another kind of object to cope it, that’s the *ViewModel*!

---

Let’s check the meaning of this view model component and how important it is in our iOS development.



## W/O ViewModel

What if we don’t introduce it in our iOS project, how could we implement it instead? 

1. Using Model instead.

  In an `UIController` subclass implementation, it requests the data via networking or database and deserialize it to model objects, then pass them to view objects directly. ***This is exactly the solution I found in many iOS projects before***. Now here is the relationship:

  * Controller retains the business data model and view.
  * View retains the business data model and notify the user interaction changes via the models.
  * View requests via network or database to get something new directly, sometimes, without interactions via controller.
  * Model may need more property extensions for UI view objects’ state.

  From this point, the controller loses its original responsibilities completely, the model class added some specific view classes’ state management, the view couldn’t be reused without another data model, the official MVC pattern breaks easily. It sucks!

2. Let controller copes it.

  The controller aims to resolve this task as the pattern expected, so updating the views by business data accurately one by one looks good. That’s OK, for a simple page which has only some basic elements like `UILabel`, `UITextField` and so on, we could pass the fundamental model properties to them and subscribe the custom user interaction actions in controller side.

  How about a complex view like a view based on `UITableView` , `UICollectionView` or other long depths structure view? It must be a special model (class) designed for it, otherwise, bad design!

#### OOP

Back to the aspect of OOP (Object-Oriented Programming), all the classes are either model classes, view classes or controller classes. Every class should can be reused somewhere with a significant meaning with its own independent design.

* A model class indicates the corresponding business logic including all the properties and functions.
* A view class indicates could be initialized in a controller to display its appearance with predefined data model.
* A controller class indicates the corresponding page could be present with some input source.

*A view class should never be built upon any business logics*, if it does, the whole view class’s data flow will be reconstructed once the business model class get changed, this offen happens in our daily development. Besides, a view class may be reused in other page with different business model class (in future), in that case, it must merge the different model classes into one dirty aggregated model or convert one model to another existing business model before reusing the view. I can’t imagine the evil’s ending.

Actually, a model class describes the business model’s properties from the backend database, it’s completely not for UI presentation sometimes. For example, there is a retweet count containing in a tweet model which will be displayed in a view element with different short format, it’s the controller’s responsibility to validate and control the final element’s content instead of view class directly.



## With ViewModel

Let’s see how the ViewModel resolve the above issues.

In the new `UIViewController` subclass implementation, that is, the controller always request the business model via network or database and retains them in its lifetime, then convert them to the target view models of its subviews, **view model is the main structure between view and model via controller**. The view model also supply the delegate functions for view class to notify the view’s user interaction changes to controller, then controller take actions on its model…

With this design, the business model is always invisible to view, it’s duty of controller to ***bridge*** the business model to view object via view model. As apple MVC documentation expected, the model objects only focus on its own business logic, it doesn’t care about any UI view presentation issues. The view objects doesn't need to know the data source to be presented comes from exactly.

So will it make the controller become more massive situation? It depends on the practice in project.



## ViewModel in Practice

Let’s check out a real demo project for it, I build a simple iOS client to show the starred repositories on Github via their open API, [here](https://github.com/xingheng/mvc-viewmodel) is the full source code.

![screenshot](/images/mvc-viewmodel-screenshot.png)

```bash
MVC-ViewModel
├── AppDelegate.h
├── AppDelegate.m
├── Controllers
│   ├── RepositoryViewController.h
│   ├── RepositoryViewController.m
│   ├── SettingsViewController.h
│   └── SettingsViewController.m
├── Models
│   ├── RepositoryModel.h
│   └── RepositoryModel.m
├── ViewModels
│   ├── RepositoryViewModel.h
│   └── RepositoryViewModel.m
├── Views
    ├── RepositoryCollectionView.h
    └── RepositoryCollectionView.m
```

This brief  `tree` command’s partial output shows the full source files and their identities, let me clarify the details: In the main entry of `Appdelegate`, it setups a tabBar controller with `RepositoryViewController` and `SettingViewController` as the root view controller. In the  `SettingViewController`, it just asks for user input to get a Github username for the latter repository request and saves the value in `NSUserDefaults`. `RepositoryViewController` will start to request an initial page of starred repository list via model class `RepositoryModel` and save the results in itself, it also creates the `RepositoryCollectionView` view object and prepares to pass data source to it.

Let’s see the interface of `RepositoryCollectionView` first:

```objective-c
@protocol RepositoryViewProtocol <NSObject>

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *subtitle;
@property (nonatomic, assign) BOOL visited;
@property (nonatomic, copy, readonly) void (^ onRepositoryTapped)(void);

@end

@interface RepositoryCollectionView : UICollectionView <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray<id<RepositoryViewProtocol> > *dataItems;
@property (nonatomic, copy) void (^ didScrollToEnd)(void);

@end
```

`RepositoryCollectionView` has implemented the full view appearance including its `UICollectionViewCell` subclass inside, so the callers don’t need to construct the additional cell elements when using it, assigning the predefined data source via `dataItems` property instead is enough, here the `RepositoryViewProtocol` type is. But wait, why is it a protocol? why not using a class instead? Is it the view model we said above?

Let’s dig it into a deep depth. First, `id<RepositoryViewProtocol>` must be an objective-c object, that is, a class object here passing by reference, so `dataItems` is exactly the view model objects here, we just don’t limit what kind of concrete class is used. “I don’t care about what it is, give me the data source that implemented the protocol before using me, check out the protocol definition directly”, the view class said. Second, if it using the concrete class like `RepositoryViewModel` class instead here, then the caller need to convert the business model to the `RepositoryViewModel` instead. Seems right, aha? Yes, the data flow is so right, but it’s not so good for the *class owner*, if the file `RepositoryCollectionView.h/m` owns the view model class, then it’d better let the view model class know what kind of data source will be converted from. On the other hand, let’s take the `title` property in the `RepositoryViewProtocol` protocol as an example, it’s defined as `readonly`, this means the current view won’t change the `title` property in its lifecycle in the implementation inside. How  could we let the callers know this behavior within the implementation without reading the source code in `.m` file? The answer is impossible except using `@protocol` interface.

Can’t we define the `RepositoryViewModel` view model class for `dataItems` in the view header file directly? No, we can, but it’s not so polite as the above discussion. However, I (the author) recommend using the `@protocol` implementation, *think [Interface segregation principle](https://en.wikipedia.org/wiki/Interface_segregation_principle) of [SOLID](https://en.wikipedia.org/wiki/SOLID) principles*.

So who will use the protocol in the end? The view model class `RepositoryViewModel` in the same filename’s source files does it, check the above `tree` output, it’s defined outside of view `RepositoryCollectionView.h/m` file because there are no direct relations between them.

```objective-c
#import "RepositoryCollectionView.h"

@interface RepositoryViewModel : NSObject <RepositoryViewProtocol>

@property (nonatomic, strong) id context;
@property (nonatomic, assign) BOOL visited;
@property (nonatomic, copy) void (^ onRepositoryTapped)(void);

@end
 
@implementation RepositoryViewModel

- (NSString *)title
{
    return nil;
}

- (NSString *)subtitle
{
    return nil;
}

@end
```

We could see that the `onRepositoryTapped` property defined as default `readwrite` here, but the protocol `RepositoryViewProtocol` requires the `readonly` attribute, that’s the meaning and difference of view model class and protocol. For the `visited` property definition, it indicates the view class will also need to change that value to save the cells’ visited state in its own implementation.

So what’s the wildcard type of `context` property? It doesn’t exist in the view protocol, why should we need it here? Actually it’s the *bridge* to the real business model, think about there may be multiple different types of business model classes mapping to this view class, or some client-only placeholder model objects will be placed there. With this `context` property entry, we could resolve the property mapping easily.

Let’s introduce a simple macro for forwarding the right property to view property.

```objective-c
#define DataItemGetterForward(_source_cls_, _expr_)            \
    if ([self.context isKindOfClass:_source_cls_.class]) {     \
        return ((_source_cls_ *)self.context)._expr_;          \
    }
```

Then use it in the getter method of `title`:

```objective-c
- (NSString *)title
{
    DataItemGetterForward(RepositoryModel, full_name)
    return nil;
}
```

This is an optional but gentle style, it works for the simple bridge property mapping cases, for the complex mapping expressions, it still needs to write by hand. Let’s take a look another fantastic macro I wrote for view model constructers.

```objective-c
#define DataItemInitializerDeclaration(_containing_cls_, _source_cls_)     \
    + (instancetype)dataItemWith ## _source_cls_: (_source_cls_ *)context; \
    + (instancetype)dataItemWith ## _source_cls_: (_source_cls_ *)context  \
         block: (void (^ _Nullable)(_source_cls_ *source, _containing_cls_ *data))block;     \
    + (NSArray<_containing_cls_ *> *)dataItemsWith ## _source_cls_ ## s:(NSArray<_source_cls_ *> *)context;                                \
    + (NSArray<_containing_cls_ *> *)dataItemsWith ## _source_cls_ ## s:(NSArray<_source_cls_ *> *)context                                 \
         block: (void (^ _Nullable)(_source_cls_ *source, _containing_cls_ *data))block;

#define DataItemInitializerImplementation(_containing_cls_, _source_cls_)                                    \
    + (instancetype)dataItemWith ## _source_cls_: (_source_cls_ *)context                                    \
    {                                                                                                        \
        return [self dataItemWith ## _source_cls_:context block:nil];                                        \
    }                                                                                                        \
    + (instancetype)dataItemWith ## _source_cls_: (_source_cls_ *)context                                    \
         block: (void (^ _Nullable)(_source_cls_ *source, _containing_cls_ *data))block                                        \
    {                                                                                                        \
        _containing_cls_ *data = [self new];                                                                 \
        data.context = context;                                                                              \
        if (block) {                                                                                         \
            block(context, data);                                                                            \
        }                                                                                                    \
        return data;                                                                                         \
    }                                                                                                        \
    + (NSArray<_containing_cls_ *> *)dataItemsWith ## _source_cls_ ## s:(NSArray<_source_cls_ *> *)context                                                                   \
    {                                                                                                        \
        return [self dataItemsWith ## _source_cls_ ## s:context block:nil];                                  \
    }                                                                                                        \
    + (NSArray<_containing_cls_ *> *)dataItemsWith ## _source_cls_ ## s:(NSArray<_source_cls_ *> *)context                                                                   \
         block: (void (^ _Nullable)(_source_cls_ *source, _containing_cls_ *data))block                                        \
    {                                                                                                        \
        NSMutableArray<_containing_cls_ *> *items = [[NSMutableArray alloc] initWithCapacity:context.count]; \
        for (_source_cls_ *c in context) {                                                                   \
            [items addObject:[self dataItemWith ## _source_cls_:c block:block]];                             \
        }                                                                                                    \
        return items;                                                                                        \
    }
```

Then use it within the view model class:

```objective-c
@interface RepositoryViewModel : NSObject <RepositoryViewProtocol>

DataItemInitializerDeclaration(RepositoryViewModel, RepositoryModel)

@end

@implementation RepositoryViewModel

DataItemInitializerImplementation(RepositoryViewModel, RepositoryModel)

@end
```

Now two pairs of construct methods will be ready there for us to quickly convert the `RepositoryModel` model to `RepositoryViewModel` view model, of course it’s so easy to extend to other business models quickly, too. That’s so nice, aha? I always like this stuff to avoid the duplicated method implementations.

Finally, how does the controller organize the model data to view? Just give a glance:

```objective-c
self.collectionView.dataItems = [RepositoryViewModel dataItemsWithRepositoryModels:self.allRepos block:^(RepositoryModel * _Nonnull source, RepositoryViewModel * _Nonnull data) {
    data.onRepositoryTapped = ^{
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://github.com/%@", source.full_name]];
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
        [self presentViewController:safariVC animated:YES completion:nil];
    };
}];
```

The business models `self.allRepos` will be mapped to class `RepositoryViewModel` which be passed to the view’s data source directly. Durning the mapping process, it also setups the custom user interaction block via `onRepositoryTapped` property for every cell, this is still under the control of controller object.

Now let’s review the component’s relationship again:

* Model class isn’t used in view or view’s protocol.
* View class doesn’t know the existence of view model.
* Controller class control the entire data flow from business model to view model.

Does the controller class has an over source lines? No, it’s only 124 lines what I did the job, including build a few views programmatically, request business data and do the conversion by pages, all the massive logic has been separated to other components, the line result is acceptable, for this simple page at least.

Take a look at the `readwrite` `visited` property’s usage, it doesn’t occur in any places in controller, model and view model, just defined in view model class and used in the view class itself. How to explain this? Well, as the view protocol’s declaration, the view class needs a read-write property in the view model class to save the cell’s state when user tapping it, then update the cell’s appearance by the visited state. A protocol can’t save the state data directly because it isn’t an object, so *ask for help* from view model class instead. The view object supplies this function to the caller but it’s also could be disabled by override the getter & setter methods of `visited` property with an empty implementation, no modification required in view class itself.

If something changed in business model class, what we need to do is just updating the related code usages in view model class and controller, it doesn’t impact the view class at all. That’s right!

If there are some view design required which have the exactly same appearance with existing ones, just make a new model bridge in the view model class. it doesn’t need to modify the view protocol or other internal data structure, either. Of course, feel free to extend the view protocol if necessary.



## MVVM

Compared with [MVVM](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) (Model-View-ViewModel), what’s the differences from our topic view model? Actually, they are the same functions which act as an abstraction of view exposing public properties and delegate actions except no binding technology. We could see that all the interactions design solutions are built without any hack magics in the demo project, however MVVM on iOS needs [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) framework, Microsoft also provides the builtin binding capability via [XAML](https://en.wikipedia.org/wiki/XAML).



## Conclusion

View model isn’t for MVC or MVVM pattern specially, it’s designed for view component, so we could always use its thoughts to build an object-oriented view class.
