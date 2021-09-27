//
//  PageContentViewController.swift
//  LightPagingKit
//
//  Created by Ryan on 2021/5/10.
//
// 1.scrollview
// 2.数据
// 3.滑动距离的关联

import UIKit

public protocol PageContentViewControllerDelegate: AnyObject {
    func contentViewController(viewController: PageContentViewController, willBeginManualScrollOn index: Int)
    
    func contentViewController(viewController: PageContentViewController, didManualScrollOn index: Int, percent: CGFloat)
    
    func contentViewController(viewController: PageContentViewController, didEndManualScrollOn index: Int)
}

extension PageContentViewControllerDelegate {
    func contentViewController(viewController: PageContentViewController, willBeginManualScrollOn index: Int) {}
    
    func contentViewController(viewController: PageContentViewController, didManualScrollOn index: Int, percent: CGFloat) {}

    func contentViewController(viewController: PageContentViewController, didEndManualScrollOn index: Int) {}
}

public protocol PageContentViewControllerDataSource: AnyObject {
    /// 容器中一共有多少控制器
    /// - Parameters:
    ///   - viewController:子控制器
    /// - Returns: 子控制器数量
    func numberOfItemsForContentViewController(viewController: PageContentViewController) -> Int
    
    /// 某一index处对应的子控制器
    /// - Parameters:
    ///   - viewController: 容器控制器
    ///   - index:子控制器的index
    /// - Returns:子控制器
    func contentViewController(viewController: PageContentViewController, viewControllerAt index: Int) -> UIViewController
}

public class PageContentScrollView: UIScrollView, UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

public class PageContentBottomScrollView: UIScrollView, UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

public class PageContentViewController: UIViewController {
    private var numberOfPages: Int     = 0
    private var leftSidePageIndex: Int = 0
    private var isDrag = false
    
    public weak var delegate: PageContentViewControllerDelegate?
    public weak var dataSource: PageContentViewControllerDataSource?
    
    public var cachedViewControllers = [UIViewController?]()
    
    private var leftSidePagingPercent: CGFloat {
        // 取掉整数，得到余
        let rawPagingPercent = scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.bounds.width) / scrollView.bounds.width
        return rawPagingPercent
    }
    
    public var currentPageIndex: Int {
        return calcCurrentPageIndex(from: leftSidePageIndex, pagingPercent: leftSidePagingPercent)
    }
    
    public var currentPagePercent: CGFloat {
        return calcCurrentPagingPercent(leftSidePagingPercent)
    }
    
    public let scrollView: PageContentBottomScrollView = {
        let scroll = PageContentBottomScrollView.init()
        scroll.isPagingEnabled = true
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.bounces = false
        scroll.backgroundColor = .clear
        return scroll
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        scrollView.frame = view.bounds
        scrollView.delegate = self
        view.addSubview(scrollView)
        view.addConstraints([.top, .bottom, .leading, .trailing].anchor(from: scrollView, toView: view))
        view.backgroundColor = .clear
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentSize = CGSize(width: scrollView.bounds.size.width * CGFloat(numberOfPages),
                                        height: scrollView.bounds.size.height)
        
        scrollView.contentOffset = CGPoint(x: scrollView.bounds.width * CGFloat(leftSidePageIndex), y: 0)
        
        cachedViewControllers.enumerated().forEach { (index, vc) in
            vc?.view.frame = scrollView.bounds
            vc?.view.frame.origin.x = scrollView.bounds.width * CGFloat(index)
        }
    }
    
    public func loadData() {
        guard let _dataSource = dataSource else { return }
        
        children.forEach { $0.willMove(toParent: nil) }
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        children.forEach { $0.removeFromParent() }
        
        cachedViewControllers = []
        
        numberOfPages = _dataSource.numberOfItemsForContentViewController(viewController: self)
        
        cachedViewControllers = Array(repeating: nil, count: numberOfPages)
        
        (0..<numberOfPages).forEach { index in
            let vc = _dataSource.contentViewController(viewController: self, viewControllerAt: index)
            addChild(vc)
            vc.view.frame = scrollView.bounds
            vc.view.frame.origin.x = scrollView.bounds.width * CGFloat(index)
            scrollView.addSubview(vc.view)
            vc.didMove(toParent: self)
            cachedViewControllers[index] = vc
        }
        
        leftSidePageIndex = 0
                
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    /// 滑动到指定item
    /// - Parameters:
    ///   - index: 此子控制器的index
    ///   - animated: 是否动画
    ///   - completion: 滑动完成之后的回调
    public func scrollItem(to index: Int, animated: Bool = true, completion: ((Bool) -> Void)?) {
        if animated {
            UIView.perform(.delete, on: [], options: UIView.AnimationOptions.init(rawValue: 0)) {
                self.scrollView.contentOffset = CGPoint.init(x: self.scrollView.bounds.width * CGFloat(index), y: 0)
            } completion: { finished in
                self.leftSidePageIndex = index
                completion?(finished)
            }
        } else {
            scrollView.setContentOffset(CGPoint.init(x: scrollView.bounds.width * CGFloat(index), y: 0), animated: false)
            leftSidePageIndex = index
            completion?(true)
        }
    }
    
    private func calcCurrentPagingPercent(_ leftSidePagingPercent: CGFloat) -> CGFloat {
        if leftSidePagingPercent >= 0.5 {
            return (leftSidePagingPercent - 1)
        } else {
            return leftSidePagingPercent
        }
    }
    
    private func calcCurrentPageIndex(from leftSidePageIndex: Int, pagingPercent: CGFloat) -> Int {
        let scrollToRightSide = (pagingPercent >= 0.5)
        let rightSidePageIndex = min(cachedViewControllers.endIndex, leftSidePageIndex + 1)
        return scrollToRightSide ? rightSidePageIndex : leftSidePageIndex
    }
}

extension PageContentViewController: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard !(scrollView.isDragging && scrollView.isDecelerating) else { return }
        
        leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        delegate?.contentViewController(viewController: self, willBeginManualScrollOn: leftSidePageIndex)
        
        isDrag = true
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isDrag { return }
        
        leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        
        let normalizedPercent = calcCurrentPagingPercent(leftSidePagingPercent)
        let currentIndex = calcCurrentPageIndex(from: leftSidePageIndex, pagingPercent: leftSidePagingPercent)
        
        delegate?.contentViewController(viewController: self, didManualScrollOn: currentIndex, percent: normalizedPercent)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard 0 <= scrollView.bounds.origin.x, scrollView.bounds.maxX < scrollView.contentSize.width else { return }
        
        if isDrag {
            leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            delegate?.contentViewController(viewController: self, didEndManualScrollOn: leftSidePageIndex)
        }
        
        isDrag = false
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        
        if isDrag {
            leftSidePageIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            delegate?.contentViewController(viewController: self, didEndManualScrollOn: leftSidePageIndex)
        }
        isDrag = false

    }
}

private extension Array where Element == NSLayoutConstraint.Attribute {
    func anchor(from fromView: UIView, toView: UIView) -> [NSLayoutConstraint] {
        // 设置上下左右都紧贴的布局
        // 转化为：view1.attr1 = view2.attr2 * multiplier + constant
        return map {
            NSLayoutConstraint(item: fromView,
                               attribute: $0,
                               relatedBy: .equal,
                               toItem: toView,
                               attribute: $0,
                               multiplier: 1,
                               constant: 0)
        }
    }
}

