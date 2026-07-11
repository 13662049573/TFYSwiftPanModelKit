//
//  TFYSwiftPopupView.swift
//  TFYSwiftPanModel
//
//  弹窗视图核心类，管理展示/隐藏生命周期。
//

import UIKit

/// 弹窗视图，管理 animator + backgroundView 的展示与隐藏生命周期
open class TFYSwiftPopupView: UIView {

    public weak var delegate: TFYSwiftPopupViewDelegate?
    public var animator: TFYSwiftPopupViewAnimator?
    public var configuration: TFYSwiftPopupViewConfiguration = TFYSwiftPopupViewConfiguration()
    public private(set) var backgroundView: TFYSwiftPopupBackgroundView?
    public private(set) var isShowing: Bool = false

    private weak var containerView: UIView?
    private var autoDismissTimer: Timer?
    private var keyboardObservers: [NSObjectProtocol] = []
    private var backgroundObserver: NSObjectProtocol?
    private var originalTransform: CGAffineTransform = .identity
    private var originalCenter: CGPoint = .zero
    private var originalBounds: CGRect = .zero
    private var keyboardConstraintOffset: CGFloat = 0
    private var dismissGestures: [UIGestureRecognizer] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 在指定容器中展示弹窗（支持配置对象与容器自动发现）
    public func show(
        in container: UIView? = nil,
        animator: TFYSwiftPopupViewAnimator,
        configuration: TFYSwiftPopupViewConfiguration? = nil,
        backgroundView: TFYSwiftPopupBackgroundView? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let config = configuration ?? self.configuration
        guard config.validate() else {
            completion?()
            return
        }
        self.configuration = config


        let showBlock = { [weak self] in
            guard let self else { return }
            self.resolveContainer(from: container, configuration: config) { resolvedContainer in
                guard let resolvedContainer else {
                    completion?()
                    return
                }
                self.performShow(
                    in: resolvedContainer,
                    animator: animator,
                    configuration: config,
                    backgroundView: backgroundView,
                    animated: animated,
                    completion: completion
                )
            }
        }

        if config.enablePriorityManagement {
            TFYSwiftPopupPriorityManager.shared.requestShow(
                popup: self,
                priority: config.priority,
                strategy: config.priorityStrategy,
                maxWaitingTime: config.maxWaitingTime > 0 ? config.maxWaitingTime : TFYSwiftPopupPriorityManager.shared.defaultMaxWaitingTime,
                canBeReplaced: config.canBeReplacedByHigherPriority,
                showBlock: showBlock
            )
        } else {
            showBlock()
        }
    }

    /// 兼容旧 API
    public func show(
        in container: UIView,
        animator: TFYSwiftPopupViewAnimator,
        backgroundView: TFYSwiftPopupBackgroundView? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        show(
            in: container as UIView?,
            animator: animator,
            configuration: configuration,
            backgroundView: backgroundView,
            animated: animated,
            completion: completion
        )
    }

    /// 关闭弹窗
    open func dismissAnimated(_ animated: Bool, completion: (() -> Void)? = nil) {
        guard isShowing, let animator = animator, let bgView = backgroundView else {
            completion?()
            return
        }

        if delegate?.popupViewShouldDismiss(self) == false { return }

        invalidateObserversAndTimers()
        delegate?.popupViewWillDisappear(self)

        animator.dismiss(contentView: self, backgroundView: bgView, animated: animated) { [weak self] in
            guard let self else { return }
            self.removeFromSuperview()
            bgView.removeFromSuperview()
            self.isShowing = false
            self.animator = nil
            self.backgroundView = nil
            self.transform = .identity
            TFYSwiftPopupPriorityManager.shared.remove(popup: self)
            self.delegate?.popupViewDidDisappear(self)
            completion?()
        }
    }

    // MARK: - Private

    private func performShow(
        in container: UIView,
        animator: TFYSwiftPopupViewAnimator,
        configuration: TFYSwiftPopupViewConfiguration,
        backgroundView: TFYSwiftPopupBackgroundView?,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        guard !isShowing else { return }

        self.animator = animator
        self.containerView = container
        originalTransform = .identity
        originalCenter = .zero
        originalBounds = .zero
        keyboardConstraintOffset = 0

        applyTheme(from: configuration)
        if configuration.cornerRadius > 0 {
            layer.cornerRadius = configuration.cornerRadius
            layer.masksToBounds = true
        }

        isUserInteractionEnabled = configuration.isInteractive

        let bgView = backgroundView ?? makeBackgroundView(configuration: configuration)
        self.backgroundView = bgView
        bgView.frame = container.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let allowsBackgroundDismiss = configuration.isDismissible && configuration.dismissOnBackgroundTap
        bgView.isUserInteractionEnabled = !configuration.isPenetrable
        if allowsBackgroundDismiss {
            bgView.addTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
        }

        if configuration.respectsSafeArea {
            let insets = configuration.safeAreaInsets == .zero
                ? TFYSwiftWindowHelper.safeAreaInsets
                : configuration.safeAreaInsets
            layoutMargins = insets
        }

        container.addSubview(bgView)
        container.addSubview(self)

        animator.setup(popupView: self, contentView: self, backgroundView: bgView)

        if configuration.enableHapticFeedback {
            TFYSwiftHapticFeedback.impact(.light)
        }

        setupKeyboardHandling(configuration: configuration)
        setupBackgroundDismissIfNeeded(configuration: configuration)
        setupAutoDismissIfNeeded(configuration: configuration)
        setupDismissGestures(configuration: configuration)
        applyAccessibility(configuration: configuration)

        if configuration.enablePriorityManagement {
            // maxPopupCount 限制队列总量，不改变默认同时展示数
            TFYSwiftPopupPriorityManager.shared.enforceMaxPopupCount(configuration.maxPopupCount)
        }

        delegate?.popupViewWillAppear(self)
        isShowing = true

        animator.display(contentView: self, backgroundView: bgView, animated: animated) { [weak self] in
            guard let self else { return }
            self.delegate?.popupViewDidAppear(self)
            completion?()
        }
    }

    private func resolveContainer(
        from container: UIView?,
        configuration: TFYSwiftPopupViewConfiguration,
        completion: @escaping (UIView?) -> Void
    ) {
        if let container {
            completion(container)
            return
        }

        guard configuration.enableContainerAutoDiscovery else {
            completion(TFYSwiftPopupContainerManagerConvenience.getCurrentWindowContainer()?.containerView)
            return
        }

        var didComplete = false
        let finish: (UIView?) -> Void = { view in
            guard !didComplete else { return }
            didComplete = true
            completion(view)
        }

        let timeout = configuration.containerSelectionTimeout
        if timeout > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                if configuration.allowContainerFallback {
                    finish(TFYSwiftPopupContainerManagerConvenience.getCurrentWindowContainer()?.containerView)
                } else {
                    finish(nil)
                }
            }
        }

        let selector = configuration.customContainerSelector
            ?? TFYSwiftPopupContainerManager.shared.defaultContainerSelector()
        TFYSwiftPopupContainerManager.shared.selectBestContainer(selector: selector) { info, _ in
            if let view = info?.containerView {
                finish(view)
            } else if configuration.allowContainerFallback {
                finish(TFYSwiftPopupContainerManagerConvenience.getCurrentWindowContainer()?.containerView)
            } else {
                finish(nil)
            }
        }
    }

    private func makeBackgroundView(configuration: TFYSwiftPopupViewConfiguration) -> TFYSwiftPopupBackgroundView {
        let bg = TFYSwiftPopupBackgroundView()
        switch configuration.backgroundStyle {
        case .solidColor:
            bg.style = .solidColor
            bg.color = configuration.backgroundColor
        case .blur:
            bg.style = .blur
            bg.blurEffectStyle = resolvedBlurStyle(for: configuration)
        case .gradient:
            bg.style = .gradient
        case .custom:
            bg.style = .custom
        }
        return bg
    }

    private func resolvedBlurStyle(for configuration: TFYSwiftPopupViewConfiguration) -> UIBlurEffect.Style {
        if configuration.theme == .default {
            return traitCollection.userInterfaceStyle == .dark ? .systemMaterialDark : .systemMaterialLight
        }
        return configuration.blurStyle
    }

    private func applyTheme(from configuration: TFYSwiftPopupViewConfiguration) {
        let theme = configuration.theme == .default ? TFYSwiftPopupViewConfiguration.currentTheme() : configuration.theme
        switch theme {
        case .light:
            if backgroundColor == nil { backgroundColor = .systemBackground }
        case .dark:
            if backgroundColor == nil { backgroundColor = .secondarySystemBackground }
        case .custom:
            if let color = configuration.customThemeBackgroundColor {
                backgroundColor = color
            }
            if configuration.customThemeCornerRadius > 0 {
                layer.cornerRadius = configuration.customThemeCornerRadius
            }
        case .default:
            break
        }
    }

    private func applyAccessibility(configuration: TFYSwiftPopupViewConfiguration) {
        guard configuration.enableAccessibility else {
            accessibilityViewIsModal = false
            backgroundView?.isAccessibilityElement = false
            return
        }
        accessibilityViewIsModal = true
        isAccessibilityElement = false
        accessibilityLabel = NSLocalizedString("Popup", comment: "Popup content accessibility label")
        backgroundView?.isAccessibilityElement = true
        backgroundView?.accessibilityLabel = NSLocalizedString("Dismiss background", comment: "Popup dimmed background")
        backgroundView?.accessibilityTraits = configuration.isDismissible && configuration.dismissOnBackgroundTap ? .button : .none
    }

    private func setupDismissGestures(configuration: TFYSwiftPopupViewConfiguration) {
        dismissGestures.forEach { removeGestureRecognizer($0) }
        dismissGestures.removeAll()
        guard configuration.isDismissible else { return }

        if configuration.enableDragToDismiss {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleDragToDismiss(_:)))
            addGestureRecognizer(pan)
            dismissGestures.append(pan)
        }
        if configuration.enableSwipeToDismiss {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToDismiss(_:)))
            swipe.direction = [.left, .right, .down]
            addGestureRecognizer(swipe)
            dismissGestures.append(swipe)
        }
    }

    @objc private func handleDragToDismiss(_ pan: UIPanGestureRecognizer) {
        guard configuration.isDismissible else { return }
        let translation = pan.translation(in: self)
        let threshold = bounds.height * configuration.dragDismissThreshold
        switch pan.state {
        case .changed:
            if translation.y > 0 {
                transform = originalTransform.translatedBy(x: 0, y: translation.y)
            }
        case .ended, .cancelled:
            if translation.y > threshold || pan.velocity(in: self).y > 800 {
                dismissAnimated(true)
            } else {
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.transform = self?.originalTransform ?? .identity
                }
            }
        default:
            break
        }
    }

    @objc private func handleSwipeToDismiss(_ swipe: UISwipeGestureRecognizer) {
        guard configuration.isDismissible else { return }
        dismissAnimated(true)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard isShowing,
              traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyTheme(from: configuration)
        if configuration.backgroundStyle == .blur, let bg = backgroundView {
            bg.blurEffectStyle = resolvedBlurStyle(for: configuration)
        }
    }

    private func setupKeyboardHandling(configuration: TFYSwiftPopupViewConfiguration) {
        guard configuration.keyboardConfiguration.isEnabled else { return }
        let keyboardConfig = configuration.keyboardConfiguration

        let showObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: true, config: keyboardConfig)
        }
        let hideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboard(notification: notification, isShowing: false, config: keyboardConfig)
        }
        keyboardObservers = [showObserver, hideObserver]
    }

    private func handleKeyboard(
        notification: Notification,
        isShowing: Bool,
        config: TFYSwiftPopupKeyboardConfiguration
    ) {
        guard isShowing else {
            restoreKeyboardAvoidance(config: config)
            return
        }
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardFrame = frameValue.cgRectValue
        var keyboardHeight = keyboardFrame.height
        if config.respectSafeArea {
            keyboardHeight = max(0, keyboardHeight - TFYSwiftWindowHelper.safeAreaInsets.bottom)
        }
        let offset = keyboardHeight + config.additionalOffset

        switch config.avoidingMode {
        case .transform:
            UIView.animate(withDuration: config.animationDuration) { [weak self] in
                guard let self else { return }
                self.transform = self.originalTransform.translatedBy(x: 0, y: -offset)
            }
        case .constraint:
            if originalCenter == .zero { originalCenter = center }
            UIView.animate(withDuration: config.animationDuration) { [weak self] in
                guard let self else { return }
                self.keyboardConstraintOffset = offset
                self.center = CGPoint(x: self.originalCenter.x, y: self.originalCenter.y - offset)
            }
        case .resize:
            if originalBounds == .zero { originalBounds = bounds }
            let minHeight: CGFloat = 80
            let newHeight = max(minHeight, originalBounds.height - offset * 0.35)
            UIView.animate(withDuration: config.animationDuration) { [weak self] in
                guard let self else { return }
                var frame = self.frame
                frame.size.height = newHeight
                if config.respectSafeArea {
                    frame.origin.y = min(frame.origin.y, (self.superview?.bounds.height ?? frame.maxY) - newHeight - TFYSwiftWindowHelper.safeAreaInsets.bottom)
                }
                self.frame = frame
            }
        }
    }

    private func restoreKeyboardAvoidance(config: TFYSwiftPopupKeyboardConfiguration) {
        UIView.animate(withDuration: config.animationDuration) { [weak self] in
            guard let self else { return }
            switch config.avoidingMode {
            case .transform:
                self.transform = self.originalTransform
            case .constraint:
                if self.originalCenter != .zero {
                    self.center = self.originalCenter
                }
                self.keyboardConstraintOffset = 0
            case .resize:
                if self.originalBounds != .zero {
                    var frame = self.frame
                    frame.size = self.originalBounds.size
                    self.frame = frame
                    self.bounds = self.originalBounds
                }
            }
        }
    }

    private func setupBackgroundDismissIfNeeded(configuration: TFYSwiftPopupViewConfiguration) {
        guard configuration.isDismissible, configuration.dismissWhenAppGoesToBackground else { return }
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.dismissAnimated(true)
        }
    }

    private func setupAutoDismissIfNeeded(configuration: TFYSwiftPopupViewConfiguration) {
        guard configuration.isDismissible, configuration.autoDismissDelay > 0 else { return }
        autoDismissTimer?.invalidate()
        autoDismissTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.autoDismissDelay,
            repeats: false
        ) { [weak self] _ in
            self?.dismissAnimated(true)
        }
    }

    private func invalidateObserversAndTimers() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        keyboardObservers.forEach { NotificationCenter.default.removeObserver($0) }
        keyboardObservers.removeAll()
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
            self.backgroundObserver = nil
        }
        dismissGestures.forEach { removeGestureRecognizer($0) }
        dismissGestures.removeAll()
    }

    @objc private func backgroundTapped() {
        delegate?.popupViewDidTapBackground(self)
        guard configuration.isDismissible, configuration.dismissOnBackgroundTap else { return }
        dismissAnimated(true)
    }

    deinit {
        invalidateObserversAndTimers()
        backgroundView?.removeFromSuperview()
    }
}
