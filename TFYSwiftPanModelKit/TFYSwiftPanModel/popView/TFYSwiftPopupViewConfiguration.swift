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
    /// 默认关闭，避免未关闭的弹窗把后续展示静默卡在队列里；需要队列时显式打开
    public var enablePriorityManagement = false

    public var containerSelectionStrategy: TFYPopupContainerSelectionStrategy = .auto
    public var preferredContainerType: TFYPopupContainerType = .window
    /// Retained for the full queued/async selection lifecycle.
    public var customContainerSelector: TFYSwiftPopupContainerSelector?
    public var enableContainerAutoDiscovery = false
    public var allowContainerFallback = true
    public var containerSelectionTimeout: TimeInterval = 5.0

    public override init() {
        super.init()
    }

    public func validate() -> Bool {
        if maxPopupCount <= 0 { return false }
        if !autoDismissDelay.isFinite || autoDismissDelay < 0 { return false }
        if !dragDismissThreshold.isFinite || dragDismissThreshold < 0 || dragDismissThreshold > 1 { return false }
        if !animationDuration.isFinite || animationDuration < 0 { return false }
        if !cornerRadius.isFinite || cornerRadius < 0 { return false }
        if !customThemeCornerRadius.isFinite || customThemeCornerRadius < 0 { return false }
        if !safeAreaInsets.top.isFinite || !safeAreaInsets.bottom.isFinite ||
           !safeAreaInsets.left.isFinite || !safeAreaInsets.right.isFinite ||
           safeAreaInsets.top < 0 || safeAreaInsets.bottom < 0 ||
           safeAreaInsets.left < 0 || safeAreaInsets.right < 0 {
            return false
        }
        if enablePriorityManagement {
            if !maxWaitingTime.isFinite || maxWaitingTime < 0 { return false }
        }
        if !containerSelectionTimeout.isFinite || containerSelectionTimeout < 0 { return false }
        if !keyboardConfiguration.validate() { return false }
        if !containerConfiguration.validate() { return false }
        return true
    }

    public static func currentTheme() -> TFYPopupTheme {
        UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
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

// MARK: - Chain

public extension TFYSwiftPopupViewConfiguration {
    @discardableResult public func isDismissible(_ value: Bool) -> Self {
        isDismissible = value
        return self
    }

    @discardableResult public func isInteractive(_ value: Bool) -> Self {
        isInteractive = value
        return self
    }

    @discardableResult public func isPenetrable(_ value: Bool) -> Self {
        isPenetrable = value
        return self
    }

    @discardableResult public func backgroundStyle(_ value: TFYPopupBackgroundStyle) -> Self {
        backgroundStyle = value
        return self
    }

    @discardableResult public func backgroundColor(_ value: UIColor) -> Self {
        backgroundColor = value
        return self
    }

    @discardableResult public func blurStyle(_ value: UIBlurEffect.Style) -> Self {
        blurStyle = value
        return self
    }

    @discardableResult public func animationDuration(_ value: TimeInterval) -> Self {
        animationDuration = value
        return self
    }

    @discardableResult public func respectsSafeArea(_ value: Bool) -> Self {
        respectsSafeArea = value
        return self
    }

    @discardableResult public func safeAreaInsets(_ value: UIEdgeInsets) -> Self {
        safeAreaInsets = value
        return self
    }

    @discardableResult public func enableDragToDismiss(_ value: Bool) -> Self {
        enableDragToDismiss = value
        return self
    }

    @discardableResult public func dragDismissThreshold(_ value: CGFloat) -> Self {
        dragDismissThreshold = value
        return self
    }

    @discardableResult public func enableSwipeToDismiss(_ value: Bool) -> Self {
        enableSwipeToDismiss = value
        return self
    }

    @discardableResult public func cornerRadius(_ value: CGFloat) -> Self {
        cornerRadius = value
        return self
    }

    @discardableResult public func dismissOnBackgroundTap(_ value: Bool) -> Self {
        dismissOnBackgroundTap = value
        return self
    }

    @discardableResult public func dismissWhenAppGoesToBackground(_ value: Bool) -> Self {
        dismissWhenAppGoesToBackground = value
        return self
    }

    @discardableResult public func maxPopupCount(_ value: Int) -> Self {
        maxPopupCount = value
        return self
    }

    @discardableResult public func autoDismissDelay(_ value: TimeInterval) -> Self {
        autoDismissDelay = value
        return self
    }

    @discardableResult public func enableHapticFeedback(_ value: Bool) -> Self {
        enableHapticFeedback = value
        return self
    }

    @discardableResult public func enableAccessibility(_ value: Bool) -> Self {
        enableAccessibility = value
        return self
    }

    @discardableResult public func theme(_ value: TFYPopupTheme) -> Self {
        theme = value
        return self
    }

    @discardableResult public func customThemeBackgroundColor(_ value: UIColor?) -> Self {
        customThemeBackgroundColor = value
        return self
    }

    @discardableResult public func customThemeTextColor(_ value: UIColor?) -> Self {
        customThemeTextColor = value
        return self
    }

    @discardableResult public func customThemeCornerRadius(_ value: CGFloat) -> Self {
        customThemeCornerRadius = value
        return self
    }

    @discardableResult public func keyboardConfiguration(_ value: TFYSwiftPopupKeyboardConfiguration) -> Self {
        keyboardConfiguration = value
        return self
    }

    @discardableResult public func containerConfiguration(_ value: TFYSwiftPopupContainerConfiguration) -> Self {
        containerConfiguration = value
        return self
    }

    /// 就地配置嵌套键盘项，返回自身便于继续链式赋值
    @discardableResult public func configureKeyboard(_ block: (TFYSwiftPopupKeyboardConfiguration) -> Void) -> Self {
        block(keyboardConfiguration)
        return self
    }

    /// 就地配置嵌套容器项，返回自身便于继续链式赋值
    @discardableResult public func configureContainer(_ block: (TFYSwiftPopupContainerConfiguration) -> Void) -> Self {
        block(containerConfiguration)
        return self
    }

    @discardableResult public func priority(_ value: TFYPopupPriority) -> Self {
        priority = value
        return self
    }

    @discardableResult public func priorityStrategy(_ value: TFYPopupPriorityStrategy) -> Self {
        priorityStrategy = value
        return self
    }

    @discardableResult public func canBeReplacedByHigherPriority(_ value: Bool) -> Self {
        canBeReplacedByHigherPriority = value
        return self
    }

    @discardableResult public func maxWaitingTime(_ value: TimeInterval) -> Self {
        maxWaitingTime = value
        return self
    }

    @discardableResult public func enablePriorityManagement(_ value: Bool) -> Self {
        enablePriorityManagement = value
        return self
    }

    @discardableResult public func containerSelectionStrategy(_ value: TFYPopupContainerSelectionStrategy) -> Self {
        containerSelectionStrategy = value
        return self
    }

    @discardableResult public func preferredContainerType(_ value: TFYPopupContainerType) -> Self {
        preferredContainerType = value
        return self
    }

    @discardableResult public func customContainerSelector(_ value: TFYSwiftPopupContainerSelector?) -> Self {
        customContainerSelector = value
        return self
    }

    @discardableResult public func enableContainerAutoDiscovery(_ value: Bool) -> Self {
        enableContainerAutoDiscovery = value
        return self
    }

    @discardableResult public func allowContainerFallback(_ value: Bool) -> Self {
        allowContainerFallback = value
        return self
    }

    @discardableResult public func containerSelectionTimeout(_ value: TimeInterval) -> Self {
        containerSelectionTimeout = value
        return self
    }
}
