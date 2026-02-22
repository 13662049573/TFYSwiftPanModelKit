//
//  TFYSwiftPopupContainerConfiguration.swift
//  TFYSwiftPanModel
//
//  弹窗容器尺寸与配置，由 OC TFYPopupContainerConfiguration 迁移。
//

import UIKit

/// 容器尺寸类型
public enum TFYPopupContainerDimensionType: UInt {
    case fixed = 0
    case automatic
    case ratio
    case custom
}

/// 自定义尺寸计算闭包
public typealias TFYPopupContainerDimensionHandler = (UIView) -> CGFloat

/// 容器单维尺寸配置
public final class TFYSwiftPopupContainerDimension: NSObject, NSCopying {
    public let type: TFYPopupContainerDimensionType
    public let value: CGFloat
    public let customHandler: TFYPopupContainerDimensionHandler?

    private init(type: TFYPopupContainerDimensionType, value: CGFloat, customHandler: TFYPopupContainerDimensionHandler?) {
        self.type = type
        self.value = value
        self.customHandler = customHandler
        super.init()
    }

    public static func fixed(_ value: CGFloat) -> TFYSwiftPopupContainerDimension {
        TFYSwiftPopupContainerDimension(type: .fixed, value: value, customHandler: nil)
    }

    public static func automatic() -> TFYSwiftPopupContainerDimension {
        TFYSwiftPopupContainerDimension(type: .automatic, value: 0, customHandler: nil)
    }

    public static func ratio(_ ratio: CGFloat) -> TFYSwiftPopupContainerDimension {
        TFYSwiftPopupContainerDimension(type: .ratio, value: ratio, customHandler: nil)
    }

    public static func custom(handler: @escaping TFYPopupContainerDimensionHandler) -> TFYSwiftPopupContainerDimension {
        TFYSwiftPopupContainerDimension(type: .custom, value: 0, customHandler: handler)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        TFYSwiftPopupContainerDimension(type: type, value: value, customHandler: customHandler)
    }
}

/// 弹窗容器配置
public final class TFYSwiftPopupContainerConfiguration: NSObject, NSCopying {
    public var width: TFYSwiftPopupContainerDimension
    public var height: TFYSwiftPopupContainerDimension
    public var maxWidth: CGFloat = 0
    public var hasMaxWidth = false
    public var maxHeight: CGFloat = 0
    public var hasMaxHeight = false
    public var minWidth: CGFloat = 0
    public var hasMinWidth = false
    public var minHeight: CGFloat = 0
    public var hasMinHeight = false
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    public var screenInsets: UIEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    public var cornerRadius: CGFloat = 0
    public var shadowEnabled = false
    public var shadowColor: UIColor = .black
    public var shadowOpacity: Float = 0.3
    public var shadowRadius: CGFloat = 5
    public var shadowOffset: CGSize = .zero

    public override init() {
        self.width = TFYSwiftPopupContainerDimension.fixed(280)
        self.height = TFYSwiftPopupContainerDimension.automatic()
        super.init()
    }

    public func validate() -> Bool {
        if hasMaxWidth, hasMinWidth, maxWidth < minWidth { return false }
        if hasMaxHeight, hasMinHeight, maxHeight < minHeight { return false }
        if hasMinWidth, minWidth < 0 { return false }
        if hasMinHeight, minHeight < 0 { return false }
        if hasMaxWidth, maxWidth <= 0 { return false }
        if hasMaxHeight, maxHeight <= 0 { return false }
        if cornerRadius < 0 { return false }
        if contentInsets.top < 0 || contentInsets.bottom < 0 || contentInsets.left < 0 || contentInsets.right < 0 { return false }
        if shadowEnabled, (shadowOpacity < 0 || shadowOpacity > 1 || shadowRadius < 0) { return false }
        if hasMaxWidth, maxWidth > 10000 { return false }
        if hasMaxHeight, maxHeight > 10000 { return false }
        if cornerRadius > 1000 { return false }
        return true
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupContainerConfiguration()
        c.width = (width.copy(with: zone) as? TFYSwiftPopupContainerDimension) ?? width
        c.height = (height.copy(with: zone) as? TFYSwiftPopupContainerDimension) ?? height
        c.maxWidth = maxWidth
        c.hasMaxWidth = hasMaxWidth
        c.maxHeight = maxHeight
        c.hasMaxHeight = hasMaxHeight
        c.minWidth = minWidth
        c.hasMinWidth = hasMinWidth
        c.minHeight = minHeight
        c.hasMinHeight = hasMinHeight
        c.contentInsets = contentInsets
        c.screenInsets = screenInsets
        c.cornerRadius = cornerRadius
        c.shadowEnabled = shadowEnabled
        c.shadowColor = shadowColor
        c.shadowOpacity = shadowOpacity
        c.shadowRadius = shadowRadius
        c.shadowOffset = shadowOffset
        return c
    }
}
