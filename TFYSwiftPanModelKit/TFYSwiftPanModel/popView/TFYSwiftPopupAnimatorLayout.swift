//
//  TFYSwiftPopupAnimatorLayout.swift
//  TFYSwiftPanModel
//
//  弹窗动画器布局配置，由 OC TFYPopupAnimatorLayout 迁移。
//

import UIKit

/// 动画器布局类型
public enum TFYPopupAnimatorLayoutType: UInt {
    case center = 0
    case top
    case bottom
    case leading
    case trailing
    case frame
}

// MARK: - 布局配置子类

public final class TFYSwiftPopupAnimatorLayoutCenter: NSObject, NSCopying {
    public var offsetY: CGFloat = 0
    public var offsetX: CGFloat = 0
    public var width: CGFloat = 0
    public var hasWidth: Bool = false
    public var height: CGFloat = 0
    public var hasHeight: Bool = false

    public static func layout(offsetY: CGFloat, offsetX: CGFloat, width: CGFloat = 0, height: CGFloat = 0) -> TFYSwiftPopupAnimatorLayoutCenter {
        let l = TFYSwiftPopupAnimatorLayoutCenter()
        l.offsetY = offsetY
        l.offsetX = offsetX
        l.width = width
        l.hasWidth = width > 0
        l.height = height
        l.hasHeight = height > 0
        return l
    }

    public static func `default`() -> TFYSwiftPopupAnimatorLayoutCenter {
        layout(offsetY: 0, offsetX: 0)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupAnimatorLayoutCenter()
        c.offsetY = offsetY
        c.offsetX = offsetX
        c.width = width
        c.hasWidth = hasWidth
        c.height = height
        c.hasHeight = hasHeight
        return c
    }
}

public final class TFYSwiftPopupAnimatorLayoutTop: NSObject, NSCopying {
    public var topMargin: CGFloat = 0
    public var offsetX: CGFloat = 0
    public var width: CGFloat = 0
    public var hasWidth: Bool = false
    public var height: CGFloat = 0
    public var hasHeight: Bool = false

    public static func layout(topMargin: CGFloat, offsetX: CGFloat, width: CGFloat = 0, height: CGFloat = 0) -> TFYSwiftPopupAnimatorLayoutTop {
        let l = TFYSwiftPopupAnimatorLayoutTop()
        l.topMargin = topMargin
        l.offsetX = offsetX
        l.width = width
        l.hasWidth = width > 0
        l.height = height
        l.hasHeight = height > 0
        return l
    }

    public static func `default`() -> TFYSwiftPopupAnimatorLayoutTop {
        layout(topMargin: 0, offsetX: 0)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupAnimatorLayoutTop()
        c.topMargin = topMargin
        c.offsetX = offsetX
        c.width = width
        c.hasWidth = hasWidth
        c.height = height
        c.hasHeight = hasHeight
        return c
    }
}

public final class TFYSwiftPopupAnimatorLayoutBottom: NSObject, NSCopying {
    public var bottomMargin: CGFloat = 0
    public var offsetX: CGFloat = 0
    public var width: CGFloat = 0
    public var hasWidth: Bool = false
    public var height: CGFloat = 0
    public var hasHeight: Bool = false

    public static func layout(bottomMargin: CGFloat, offsetX: CGFloat, width: CGFloat = 0, height: CGFloat = 0) -> TFYSwiftPopupAnimatorLayoutBottom {
        let l = TFYSwiftPopupAnimatorLayoutBottom()
        l.bottomMargin = bottomMargin
        l.offsetX = offsetX
        l.width = width
        l.hasWidth = width > 0
        l.height = height
        l.hasHeight = height > 0
        return l
    }

    public static func `default`() -> TFYSwiftPopupAnimatorLayoutBottom {
        layout(bottomMargin: 0, offsetX: 0)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupAnimatorLayoutBottom()
        c.bottomMargin = bottomMargin
        c.offsetX = offsetX
        c.width = width
        c.hasWidth = hasWidth
        c.height = height
        c.hasHeight = hasHeight
        return c
    }
}

public final class TFYSwiftPopupAnimatorLayoutLeading: NSObject, NSCopying {
    public var leadingMargin: CGFloat = 0
    public var offsetY: CGFloat = 0
    public var width: CGFloat = 0
    public var hasWidth: Bool = false
    public var height: CGFloat = 0
    public var hasHeight: Bool = false

    public static func layout(leadingMargin: CGFloat, offsetY: CGFloat, width: CGFloat = 0, height: CGFloat = 0) -> TFYSwiftPopupAnimatorLayoutLeading {
        let l = TFYSwiftPopupAnimatorLayoutLeading()
        l.leadingMargin = leadingMargin
        l.offsetY = offsetY
        l.width = width
        l.hasWidth = width > 0
        l.height = height
        l.hasHeight = height > 0
        return l
    }

    public static func `default`() -> TFYSwiftPopupAnimatorLayoutLeading {
        layout(leadingMargin: 0, offsetY: 0)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupAnimatorLayoutLeading()
        c.leadingMargin = leadingMargin
        c.offsetY = offsetY
        c.width = width
        c.hasWidth = hasWidth
        c.height = height
        c.hasHeight = hasHeight
        return c
    }
}

public final class TFYSwiftPopupAnimatorLayoutTrailing: NSObject, NSCopying {
    public var trailingMargin: CGFloat = 0
    public var offsetY: CGFloat = 0
    public var width: CGFloat = 0
    public var hasWidth: Bool = false
    public var height: CGFloat = 0
    public var hasHeight: Bool = false

    public static func layout(trailingMargin: CGFloat, offsetY: CGFloat, width: CGFloat = 0, height: CGFloat = 0) -> TFYSwiftPopupAnimatorLayoutTrailing {
        let l = TFYSwiftPopupAnimatorLayoutTrailing()
        l.trailingMargin = trailingMargin
        l.offsetY = offsetY
        l.width = width
        l.hasWidth = width > 0
        l.height = height
        l.hasHeight = height > 0
        return l
    }

    public static func `default`() -> TFYSwiftPopupAnimatorLayoutTrailing {
        layout(trailingMargin: 0, offsetY: 0)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupAnimatorLayoutTrailing()
        c.trailingMargin = trailingMargin
        c.offsetY = offsetY
        c.width = width
        c.hasWidth = hasWidth
        c.height = height
        c.hasHeight = hasHeight
        return c
    }
}

// MARK: - 主布局类

public final class TFYSwiftPopupAnimatorLayout: NSObject, NSCopying {
    public private(set) var type: TFYPopupAnimatorLayoutType
    public var centerLayout: TFYSwiftPopupAnimatorLayoutCenter?
    public var topLayout: TFYSwiftPopupAnimatorLayoutTop?
    public var bottomLayout: TFYSwiftPopupAnimatorLayoutBottom?
    public var leadingLayout: TFYSwiftPopupAnimatorLayoutLeading?
    public var trailingLayout: TFYSwiftPopupAnimatorLayoutTrailing?
    public var frameLayout: CGRect = .zero

    private init(type: TFYPopupAnimatorLayoutType) {
        self.type = type
        super.init()
    }

    public static func center(_ center: TFYSwiftPopupAnimatorLayoutCenter) -> TFYSwiftPopupAnimatorLayout {
        let l = TFYSwiftPopupAnimatorLayout(type: .center)
        l.centerLayout = center
        return l
    }

    public static func top(_ top: TFYSwiftPopupAnimatorLayoutTop) -> TFYSwiftPopupAnimatorLayout {
        let l = TFYSwiftPopupAnimatorLayout(type: .top)
        l.topLayout = top
        return l
    }

    public static func bottom(_ bottom: TFYSwiftPopupAnimatorLayoutBottom) -> TFYSwiftPopupAnimatorLayout {
        let l = TFYSwiftPopupAnimatorLayout(type: .bottom)
        l.bottomLayout = bottom
        return l
    }

    public static func leading(_ leading: TFYSwiftPopupAnimatorLayoutLeading) -> TFYSwiftPopupAnimatorLayout {
        let l = TFYSwiftPopupAnimatorLayout(type: .leading)
        l.leadingLayout = leading
        return l
    }

    public static func trailing(_ trailing: TFYSwiftPopupAnimatorLayoutTrailing) -> TFYSwiftPopupAnimatorLayout {
        let l = TFYSwiftPopupAnimatorLayout(type: .trailing)
        l.trailingLayout = trailing
        return l
    }

    public static func frame(_ frame: CGRect) -> TFYSwiftPopupAnimatorLayout {
        let l = TFYSwiftPopupAnimatorLayout(type: .frame)
        l.frameLayout = frame
        return l
    }

    public func offsetX() -> CGFloat {
        switch type {
        case .center: return centerLayout?.offsetX ?? 0
        case .top: return topLayout?.offsetX ?? 0
        case .bottom: return bottomLayout?.offsetX ?? 0
        case .leading, .trailing, .frame: return 0
        }
    }

    public func offsetY() -> CGFloat {
        switch type {
        case .center: return centerLayout?.offsetY ?? 0
        case .leading: return leadingLayout?.offsetY ?? 0
        case .trailing: return trailingLayout?.offsetY ?? 0
        case .top, .bottom, .frame: return 0
        }
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupAnimatorLayout(type: type)
        c.centerLayout = centerLayout?.copy(with: zone) as? TFYSwiftPopupAnimatorLayoutCenter
        c.topLayout = topLayout?.copy(with: zone) as? TFYSwiftPopupAnimatorLayoutTop
        c.bottomLayout = bottomLayout?.copy(with: zone) as? TFYSwiftPopupAnimatorLayoutBottom
        c.leadingLayout = leadingLayout?.copy(with: zone) as? TFYSwiftPopupAnimatorLayoutLeading
        c.trailingLayout = trailingLayout?.copy(with: zone) as? TFYSwiftPopupAnimatorLayoutTrailing
        c.frameLayout = frameLayout
        return c
    }
}
