//
//  TFYSwiftPopupViewConfiguration.swift
//  TFYSwiftPanModel
//
//  弹窗主配置类，由 OC TFYPopupViewConfiguration 迁移。
//

import UIKit

/// 背景样式
public enum TFYPopupBackgroundStyle: UInt {
    case solidColor = 0
    case blur
    case gradient
    case custom
}

/// 背景效果类型
public enum TFYPopupBackgroundEffect: UInt {
    case none = 0
    case blur
    case gradient
    case dimmed
    case custom
}

/// 弹窗主题
public enum TFYPopupTheme: UInt {
    case `default` = 0
    case light
    case dark
    case custom
}

/// 弹窗主配置
public final class TFYSwiftPopupViewConfiguration: NSObject, NSCopying {
    public var isDismissible = true
    public var isInteractive = true
    public var isPenetrable = false
    public var backgroundStyle: TFYPopupBackgroundStyle = .solidColor
    public var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    public var blurStyle: UIBlurEffect.Style = .dark
    public var animationDuration: TimeInterval = 0.25
    public var respectsSafeArea = true
    public var safeAreaInsets: UIEdgeInsets = .zero
    public var enableDragToDismiss = false
    public var dragDismissThreshold: CGFloat = 0.3
    public var enableSwipeToDismiss = false
    public var cornerRadius: CGFloat = 0
    public var dismissOnBackgroundTap = true
    public var dismissWhenAppGoesToBackground = true
    public var maxPopupCount: Int = 10
    public var autoDismissDelay: TimeInterval = 0
    public var enableHapticFeedback = true
    public var enableAccessibility = true
    public var theme: TFYPopupTheme = .default
    public var customThemeBackgroundColor: UIColor?
    public var customThemeTextColor: UIColor?
    public var customThemeCornerRadius: CGFloat = 0

    public var keyboardConfiguration: TFYSwiftPopupKeyboardConfiguration = TFYSwiftPopupKeyboardConfiguration()
    public var containerConfiguration: TFYSwiftPopupContainerConfiguration = TFYSwiftPopupContainerConfiguration()

    public var priority: TFYPopupPriority = .normal
    public var priorityStrategy: TFYPopupPriorityStrategy = .queue
    public var canBeReplacedByHigherPriority = true
    public var maxWaitingTime: TimeInterval = 0
    public var enablePriorityManagement = true

    public var containerSelectionStrategy: TFYPopupContainerSelectionStrategy = .auto
    public var preferredContainerType: TFYPopupContainerType = .window
    public weak var customContainerSelector: TFYSwiftPopupContainerSelector?
    public var enableContainerAutoDiscovery = false
    public var allowContainerFallback = true
    public var containerSelectionTimeout: TimeInterval = 5.0

    public override init() {
        super.init()
    }

    public func validate() -> Bool {
        if maxPopupCount <= 0 { return false }
        if autoDismissDelay < 0 { return false }
        if dragDismissThreshold < 0 || dragDismissThreshold > 1 { return false }
        if animationDuration < 0 { return false }
        if cornerRadius < 0 { return false }
        if customThemeCornerRadius < 0 { return false }
        if safeAreaInsets.top < 0 || safeAreaInsets.bottom < 0 ||
           safeAreaInsets.left < 0 || safeAreaInsets.right < 0 {
            return false
        }
        if enablePriorityManagement {
            if maxWaitingTime < 0 { return false }
        }
        if containerSelectionTimeout < 0 { return false }
        if !keyboardConfiguration.validate() { return false }
        if !containerConfiguration.validate() { return false }
        return true
    }

    public static func currentTheme() -> TFYPopupTheme {
        if #available(iOS 13.0, *) {
            return UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
        return .default
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupViewConfiguration()
        c.isDismissible = isDismissible
        c.isInteractive = isInteractive
        c.isPenetrable = isPenetrable
        c.backgroundStyle = backgroundStyle
        c.backgroundColor = backgroundColor
        c.blurStyle = blurStyle
        c.animationDuration = animationDuration
        c.respectsSafeArea = respectsSafeArea
        c.safeAreaInsets = safeAreaInsets
        c.enableDragToDismiss = enableDragToDismiss
        c.dragDismissThreshold = dragDismissThreshold
        c.enableSwipeToDismiss = enableSwipeToDismiss
        c.cornerRadius = cornerRadius
        c.dismissOnBackgroundTap = dismissOnBackgroundTap
        c.dismissWhenAppGoesToBackground = dismissWhenAppGoesToBackground
        c.maxPopupCount = maxPopupCount
        c.autoDismissDelay = autoDismissDelay
        c.enableHapticFeedback = enableHapticFeedback
        c.enableAccessibility = enableAccessibility
        c.theme = theme
        c.customThemeBackgroundColor = customThemeBackgroundColor
        c.customThemeTextColor = customThemeTextColor
        c.customThemeCornerRadius = customThemeCornerRadius
        c.keyboardConfiguration = (keyboardConfiguration.copy(with: zone) as? TFYSwiftPopupKeyboardConfiguration) ?? keyboardConfiguration
        c.containerConfiguration = (containerConfiguration.copy(with: zone) as? TFYSwiftPopupContainerConfiguration) ?? containerConfiguration
        c.priority = priority
        c.priorityStrategy = priorityStrategy
        c.canBeReplacedByHigherPriority = canBeReplacedByHigherPriority
        c.maxWaitingTime = maxWaitingTime
        c.enablePriorityManagement = enablePriorityManagement
        c.containerSelectionStrategy = containerSelectionStrategy
        c.preferredContainerType = preferredContainerType
        c.customContainerSelector = customContainerSelector
        c.enableContainerAutoDiscovery = enableContainerAutoDiscovery
        c.allowContainerFallback = allowContainerFallback
        c.containerSelectionTimeout = containerSelectionTimeout
        return c
    }
}
