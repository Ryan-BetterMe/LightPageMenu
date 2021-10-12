![LightPageMenu](https://user-images.githubusercontent.com/34939593/135384338-ab79e578-b5d9-4c14-bc70-e97d0bb6c9ca.png)

![platform](https://img.shields.io/badge/platform-ios-brightgreen.svg)  ![swift](https://img.shields.io/badge/swift-5.0-brightgreen.svg)  ![swift](https://img.shields.io/badge/license-MIT-brightgreen.svg)  ![swift](https://img.shields.io/badge/release-v1.0.3-brightgreen.svg)

LightPageMenu是一个非常轻量级的自定义menu和content的UI框架。相对于一些固定样式menu框架而言，它更加具有弹性。

## LightPageMenu
LightPageMenu 这个框架借鉴了[pagingKit](https://github.com/kazuhiro4949/PagingKit), 但是会更加轻量，当然，如果希望使用更复杂，更有趣的特性，可以去看看[pagingKit](https://github.com/kazuhiro4949/PagingKit), LightPageMenu移除了滑动窗口算法等内部的缓存策略，因为考虑到Menu本身是一个很轻的UI元素，即使标签很多，也不会占用太多内存。


## How to use?
LightPageMenu框架有两个关键的类：
PageMenuView
PageContentViewController

PageMenuView提供了可交互的菜单栏以供用户自定义，如果你选择PageMenuView作为菜单栏来展示，那么只需要以下几部即可。
1、继承PageMenuViewCell
2、自定义和当前Page关联的菜单栏指示视图
3、实现PageMenuViewDataSource代理
4、加载数据




## How to install?
