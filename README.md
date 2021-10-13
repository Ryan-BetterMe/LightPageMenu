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

#### 1.继承PageMenuViewCell，自定义菜单项
```Swift
class CustomPageMenuCell: PageMenuViewCell {
    var label: UILabel!
    override var isSelected: Bool {
        didSet {
            if isSelected {
                label.textColor = UIColor.cyan
            } else {
                label.textColor = UIColor.black
            }
        }
    }
    ......
}
```
如果有多个不同的菜单项，就实现多个不同类以自定义菜单栏。

#### 2.自定义和当前Page相关联的菜单栏指示视图
```Swift
  let line = UIView.init()
  line.frame = CGRect.init(x: 0, y: 0, width: 30, height: 8)
  line.backgroundColor = UIColor.red
  line.layer.cornerRadius = 4
  line.layer.masksToBounds = true
  pageView.registerFocusView(view: line)
```

可以自定义一个视图实现菜单栏指示视图。

#### 3.实现PageMenuViewDataSource代理
```Swift
extension ViewController: PageMenuViewDataSource {
    func numberOfItemsPageMenuView() -> Int {
        return datas.count
    }
    
    func pageMenuView(pageMenuView: PageMenuView, widthForItemAt index: Int) -> CGFloat {
        let width = (datas[index] as! NSString).boundingRect(with: CGSize.init(width: CGFloat.infinity, height: 20), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .medium)], context: nil).width + 2
        return width
    }
    
    func pageMenuView(pageMenuView: PageMenuView, cellForItemAt index: Int) -> PageMenuViewCell {
        let cell = CustomPageMenuCell.init()
        cell.setupCell(text: datas[index])
        
        return cell
    }
}

这里是实现DataSurce代理，提供具体的菜单项数据。

```

#### 4.加载数据

```swift
pageView.loadData()
```
当完成UI布局之后，并且所有的数据也配置完成，那么最后就需要调用loadData()来加载数据项，配置菜单项的UI了。

最后需要注意，因为这里提供了更强大的用户自定义的功能，所以当用户选择具体的某一个index的时候，是需要自己设置移动的，具体如下;
```swift
extension ViewController: PageMenuViewDelegate {
    func pageMenuView(pageMenuView: PageMenuView, didSelectedItemAt index: Int) {
        pageView.scrollItem(to: index, animated: true, completion: nil)
    }
}
```


## How to install?
