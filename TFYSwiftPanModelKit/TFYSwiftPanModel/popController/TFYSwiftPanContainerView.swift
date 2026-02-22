//
//  TFYSwiftPanContainerView.swift
//  TFYSwiftPanModel
//
//  弹窗内容容器视图，由 OC TFYPanContainerView 迁移。
//

import UIKit

/// 弹窗内容容器视图，presented view 应添加在 contentView 上
public final class TFYSwiftPanContainerView: UIView {

    public private(set) lazy var contentView: UIView = {
        let v = UIView()
        v.frame = bounds
        addSubview(v)
        return v
    }()

    public init(presentedView: UIView, frame: CGRect) {
        super.init(frame: frame)
        contentView.frame = bounds
        contentView.addSubview(presentedView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateShadow(color: UIColor, radius: CGFloat, offset: CGSize, opacity: Float) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.shadowOpacity = opacity
    }

    public func clearShadow() {
        layer.shadowColor = nil
        layer.shadowRadius = 0
        layer.shadowOffset = .zero
        layer.shadowOpacity = 0
    }
}

// MARK: - UIView + PanContainer
extension UIView {
    public var panContainerView: TFYSwiftPanContainerView? {
        subviews.first { $0 is TFYSwiftPanContainerView } as? TFYSwiftPanContainerView
    }
}
