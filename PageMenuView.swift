//
//  CustomPageView.swift
//  LightPagingKit
//
//  Created by Ryan on 2021/5/8.
//

import UIKit

public class PageMenuViewCell: UIView {
    /// 是否处于选择状态
    open var isSelected: Bool = false

    /// Cell的ID，为Cell重用设置的
    ///
    /// - Description 之前写过一版使用滑动窗口算法实现的可复用Cell，后弃用，后续可添加
    public internal(set) var identifier: String!

    /// 当前Cell的Index
    public internal(set) var index: Int!
}

open class PageMenuFocusView: UIView {
    /// FocusView此时的Index
    open var selectedIndex: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

public protocol PageMenuViewDataSource: AnyObject {
    /// 通过dataSource获取page menu view中的item个数
    ///
    /// - Returns: page menu view的items个数
    func numberOfItemsPageMenuView() -> Int

    /// 通过dataSource获取page menu view中指定index的cell
    /// - Parameters:
    ///   - pageMenuView: 请求该数据的page menu view
    ///   - index: 特定item位置的index
    /// - Returns: 一个可配置的cel，这个方法不能返回nil
    func pageMenuView(pageMenuView: PageMenuView, cellForItemAt index: Int) -> PageMenuViewCell

    /// 通过dataSource获取page menu view中cell的宽度
    ///
    /// - Parameters:
    ///   - pageMenuView: 请求该数据的page menu view
    ///   - index: 特定item位置的index
    /// - Returns: 具体item的宽度
    func pageMenuView(pageMenuView: PageMenuView, widthForItemAt index: Int) -> CGFloat
}

public protocol PageMenuViewDelegate: AnyObject {
    /// 选中某个Item
    /// - Parameters:
    ///   - pageMenuView: pageMenu视图
    ///   - index: 选中Item的index
    func pageMenuView(pageMenuView: PageMenuView, didSelectedItemAt index: Int)
}

public extension PageMenuViewDelegate {
    func pageMenuView(pageMenuView: PageMenuView, didSelectedItemAt index: Int) {}
}

public class PageMenuView: UIScrollView {
    public let focusView = PageMenuFocusView.init(frame: .zero)
    fileprivate var widths = [CGFloat]()
    fileprivate var cells = [PageMenuViewCell]()
    fileprivate(set) var containerView = UIView()
    fileprivate var touchIndex: Int?
    
    public var menuDelegate: PageMenuViewDelegate?
    public var menuDataSource: PageMenuViewDataSource?
    
    /// cell之间的间距
    public var cellSpacing: CGFloat = 0
    
    /// cell整体距离leading的距离
    public var leadingPadding: CGFloat = 0
    
    /// cell整体距离trailing的距离
    public var trailingPadding: CGFloat = 0
    
    /// focusView 距离底部的距离
    public var focusBottomPadding: CGFloat = 2.0
    
    /// 整体cell的数量
    public var itemsCount: Int {
        return numberOfItem
    }
    
    private var numberOfItem: Int = 0
    
    private var totalSpacing: CGFloat {
        return cellSpacing * numberOfCellSpacing + leadingPadding + trailingPadding
    }
    
    private var numberOfCellSpacing: CGFloat {
        return max(CGFloat(numberOfItem - 1), 0)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    private func setupView() {
        containerView.frame = bounds
        containerView.center = center
        addSubview(containerView)
        
        focusView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        containerView.addSubview(focusView)
        
        backgroundColor = .clear
        showsHorizontalScrollIndicator = false
    }
    
    /// 根据数据更新视图
    public func loadData() {
        focusView.selectedIndex = 0
        contentOffset = .zero
        
        _loadData()
        
        UIView.animate(withDuration: 0) {
            self.scrollItem(to: 0)
        }
    }
    
    /// 注册指示条视图
    public func registerFocusView(view: UIView) {
        focusView.frame = CGRect.init(origin: CGPoint.zero, size: view.frame.size)
        view.frame = focusView.bounds
        focusView.addSubview(view)
        focusView.selectedIndex = 0
        
        focusView.isHidden = true
    }
    
    /// 取出对应index里对应的视图
    public func cellForIndex(index: Int) -> PageMenuViewCell? {
        guard 0 <= index, index < cells.count else { return nil }
        
        return cells[index]
    }
    
    private func _loadData() {
        guard let dataSource = menuDataSource else { return }
        
        numberOfItem = dataSource.numberOfItemsPageMenuView()
        
        invalidateLayout()
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func invalidateLayout() {
        guard let dataSource = menuDataSource else { return }
        
        widths = []
        var containerW: CGFloat = 0
        (0..<numberOfItem).forEach { index in
            let width = dataSource.pageMenuView(pageMenuView: self, widthForItemAt: index)
            widths.append(width)
            containerW += width
        }
        
        containerW += totalSpacing
        
        contentSize = CGSize(width: containerW, height: bounds.height)
        containerView.frame = CGRect(origin: .zero, size: contentSize)
        
        focusView.isHidden = !(numberOfItem > 0)
        
        alignAllCells()
    }
    
    private func alignAllCells() {
        guard let dataSource = menuDataSource else { return }
        
        cells.forEach { $0.removeFromSuperview() }
        cells = []
        
        guard 0 < numberOfItem else { return }
        
        (0..<numberOfItem).forEach { index in
            let cell = dataSource.pageMenuView(pageMenuView: self, cellForItemAt: index)
            cell.index = index
            
            let leftEdge = (0..<cell.index).reduce(leadingPadding) { sum, index in sum + widths[index] + cellSpacing }
            cell.frame.origin = CGPoint(x: leftEdge, y: 0)
            cell.frame.size = CGSize(width: widths[index], height: containerView.bounds.height)
            containerView.addSubview(cell)
            
            cells.append(cell)
        }
        
        focusView.center = CGPoint.init(x: cells[0].center.x, y: containerView.bounds.height - focusBottomPadding - focusView.frame.height/2)
        containerView.bringSubviewToFront(focusView)
        _ = cells.selectCell(with: 0)
    }
    
    private var contentSafeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return safeAreaInsets
        } else {
            return .zero
        }
    }
    
    // 注意：为什么要添加contentInset，因为可能使用者会自定义内容的偏移量
    // 最小偏移值：默认一开始就是最小偏移值
    private var minContentOffsetX: CGFloat {
        return -(contentSafeAreaInsets.left + contentInset.left)
    }
    
    // 最大的偏移值：（contentSize.width 加上安全区距离 减去 视图宽度）
    private var maxContentOffsetX: CGFloat {
        return max(bounds.width, contentSize.width + contentSafeAreaInsets.right + contentInset.right) - bounds.width
    }
    
    /// 直接滑动到指定的Item
    /// - Parameters:
    ///   - index: 具体item的index
    ///   - animated: 是否动画
    ///   - completion: 滑动完成之后的操作
    public func scrollItem(to index: Int, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        let itemFrame = cells[index].frame
        
        let offsetX = itemFrame.midX - bounds.width/2.0
        let point = CGPoint.init(x: min(maxContentOffsetX, max(minContentOffsetX, offsetX)), y: 0)
        
        focusView.selectedIndex = index
        cells.selectCell(with: index)
        
        if !animated {
            contentOffset = point
            focusView.center = CGPoint.init(x: self.cells[index].center.x, y: self.focusView.center.y)
            focusView.layoutIfNeeded()
            
            completion?(true)
        } else {
            UIView.perform(.delete, on: [], options: UIView.AnimationOptions(rawValue: 0)) {
                self.contentOffset = point
                self.focusView.center = CGPoint.init(x: self.cells[index].center.x, y: self.focusView.center.y)
                self.focusView.layoutIfNeeded()
            } completion: { finished in
                completion?(finished)
            }
        }
    }
    
    private func correctScrollIndexAndPercent(index: Int, percent: CGFloat) -> (index: Int, percent: CGFloat) {
        let pagePositionIsLeftSide = (percent < 0)
        if pagePositionIsLeftSide {
            if index == 0 {
                return (index: index, percent: percent)
            } else {
                return (index: max(index - 1, 0), percent: percent + 1)
            }
        } else {
            return (index: index, percent: percent)
        }
    }
    
    /// 往指定index滑动
    /// - Parameters:
    ///   - index: 滑向的index
    ///   - percent: 距离该Index的percent: 正数是向右滑动 负数是向左滑动
    public func scrollItem(to index: Int, percent: CGFloat) {
        let (leftIndex, _percent) = correctScrollIndexAndPercent(index: index, percent: percent)
        
        let rightIndex = leftIndex + 1
        
        if rightIndex >= cells.count { return }
        
        let leftFrame = cells[leftIndex].frame
        let rightFrame = cells[rightIndex].frame
        
        let centerPointX = leftFrame.midX + (rightFrame.midX - leftFrame.midX) * _percent
        let offsetX = centerPointX - bounds.width / 2
        let normaizedOffsetX = min(max(minContentOffsetX, offsetX), maxContentOffsetX)
        
        focusView.center = CGPoint.init(x: centerPointX, y: focusView.center.y)
        contentOffset = CGPoint(x: normaizedOffsetX, y: 0)
        
        let centerPadding = leftFrame.midX + (rightFrame.midX - leftFrame.midX) * 0.5
        let expectedIndex = (focusView.center.x < centerPadding) ? leftIndex : rightIndex
        
        let selectedIndex = max(0, min(expectedIndex, numberOfItem - 1))
        
        if let focusIndex = focusView.selectedIndex, selectedIndex != focusIndex {
            _ = cells.selectCell(with: index)
        }
        
        focusView.selectedIndex = selectedIndex
    }
}

extension PageMenuView {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touchPoint = touches.first.flatMap({ $0.location(in: containerView) }) else { return }

        touchIndex = cells.filter { cell in cell.frame.contains(touchPoint) }.first?.index
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        defer {
            touchIndex = nil
        }

        guard let touchingIndex = self.touchIndex,
              let touchPoint = touches.first.flatMap({ $0.location(in: containerView) }),
              let touchEndedIndex = cells.filter({ cell in cell.frame.contains(touchPoint) }).first?.index else { return }

        if touchingIndex == touchEndedIndex {
            menuDelegate?.pageMenuView(pageMenuView: self, didSelectedItemAt: touchEndedIndex)
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchIndex = nil
    }
}

private extension Array where Element == PageMenuViewCell {
    func resetSelected() {
        forEach { $0.isSelected = false }
    }
    
    @discardableResult
    func selectCell(with index: Int) -> Int? {
        resetSelected()
        let selectedCell = filter { $0.index == index }.first
        selectedCell?.isSelected = true
        return selectedCell?.index
    }
}
