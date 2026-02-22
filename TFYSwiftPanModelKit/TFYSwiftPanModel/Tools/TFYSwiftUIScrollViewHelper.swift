//
//  TFYSwiftUIScrollViewHelper.swift
//  TFYSwiftPanModel
//
//  UIScrollView 滚动状态辅助扩展，由 OC UIScrollView+Helper 迁移。
//

import UIKit

extension UIScrollView {

    /// 当前是否正在滚动（拖拽但未减速，或正在跟踪手势）
    var isScrolling: Bool {
        guard window != nil else { return false }
        return (isDragging && !isDecelerating) || isTracking
    }

    /// 是否滚动到顶部
    func panIsAtTop() -> Bool {
        contentOffset.y <= -contentInset.top + 0.5
    }
}
