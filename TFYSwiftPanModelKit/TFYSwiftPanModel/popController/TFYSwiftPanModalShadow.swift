//
//  TFYSwiftPanModalShadow.swift
//  TFYSwiftPanModel
//
//  PanModal 阴影配置，由 OC TFYPanModalShadow 迁移。
//

import UIKit

/// PanModal 弹窗阴影配置
public final class TFYSwiftPanModalShadow: NSObject {
    public var shadowColor: UIColor
    public var shadowRadius: CGFloat
    public var shadowOffset: CGSize
    public var shadowOpacity: CGFloat

    public init(color: UIColor, radius: CGFloat, offset: CGSize, opacity: CGFloat) {
        self.shadowColor = color
        self.shadowRadius = radius
        self.shadowOffset = offset
        self.shadowOpacity = opacity
        super.init()
    }

    /// 无阴影配置
    public static let none = TFYSwiftPanModalShadow(color: .clear, radius: 0, offset: .zero, opacity: 0)

    @available(*, deprecated, renamed: "none")
    public static func shadowNil() -> TFYSwiftPanModalShadow { .none }
}
