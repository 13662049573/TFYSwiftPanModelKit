//
//  TFYSwiftPopupView.swift
//  TFYSwiftPanModel
//
//  弹窗视图核心类，管理展示/隐藏生命周期。
//

import UIKit

enum TFYSwiftPopupLayoutHelper {
    /// Returns the minimum upward movement required to keep a popup above the keyboard.
    static func keyboardAvoidanceOffset(
        popupFrame: CGRect,
        keyboardFrame: CGRect,
        additionalOffset: CGFloat,
        safeAreaBottom: CGFloat
    ) -> CGFloat {
        guard popupFrame.width > 0,
              popupFrame.height > 0,
              keyboardFrame.width > 0,
              keyboardFrame.height > 0,
              popupFrame.maxX > keyboardFrame.minX,
              popupFrame.minX < keyboardFrame.maxX else {
            return 0
        }
        let effectiveKeyboardTop = keyboardFrame.minY + max(0, safeAreaBottom)
        let overlap = popupFrame.maxY - effectiveKeyboardTop
        return overlap > 0 ? overlap + max(0, additionalOffset) : 0
    }
}

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
    private var originalFrame: CGRect = .zero
    private var keyboardConstraintOffset: CGFloat = 0
    private var dismissGestures: [UIGestureRecognizer] = []
    private var isDismissing = false

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
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.show(
                    in: container,
                    animator: animator,
                    configuration: configuration,
                    backgroundView: backgroundView,
                    animated: animated,
                    completion: completion
                )
            }
            return
        }

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
                    // 未能解析容器时必须出队，否则会永久占用 displayed 槽位
                    TFYSwiftPopupPriorityManager.shared.remove(popup: self)
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
            TFYSwiftPopupPriorityManager.shared.enforceMaxPopupCount(config.maxPopupCount)
            let accepted = TFYSwiftPopupPriorityManager.shared.requestShow(
                popup: self,
                priority: config.priority,
                strategy: config.priorityStrategy,
                maxWaitingTime: config.maxWaitingTime > 0 ? config.maxWaitingTime : TFYSwiftPopupPriorityManager.shared.defaultMaxWaitingTime,
                canBeReplaced: config.canBeReplacedByHigherPriority,
                showBlock: showBlock
            )
            if !accepted {
                completion?()
            }
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
    /// - Parameters:
    ///   - animated: 是否动画
    ///   - force: true 时跳过 `popupViewShouldDismiss`（用于关闭按钮等程序化关闭）
    ///   - completion: 完成回调
    open func dismissAnimated(_ animated: Bool, force: Bool = false, completion: (() -> Void)? = nil) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.dismissAnimated(animated, force: force, completion: completion)
            }
            return
        }

        guard isShowing else {
            // 未成功展示时也要从优先级队列移除，避免卡住后续弹窗
            TFYSwiftPopupPriorityManager.shared.remove(popup: self)
            completion?()
            return
        }
        guard !isDismissing else {
            completion?()
            return
        }

        if !force, delegate?.popupViewShouldDismiss(self) == false { return }

        isDismissing = true
        invalidateObserversAndTimers()
        delegate?.popupViewWillDisappear(self)

        guard let animator, let bgView = backgroundView else {
            completeDismiss(backgroundView: backgroundView, completion: completion)
            return
        }

        animator.dismiss(contentView: self, backgroundView: bgView, animated: animated) { [weak self] in
            guard let self else { return }
            self.completeDismiss(backgroundView: bgView, completion: completion)
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
        guard !isShowing else {
            completion?()
            return
        }

        invalidateObserversAndTimers()
        isDismissing = false
        self.animator = animator
        self.containerView = container
        originalTransform = .identity
        originalCenter = .zero
        originalBounds = .zero
        originalFrame = .zero
        keyboardConstraintOffset = 0

        alpha = 1
        transform = .identity
        layer.transform = CATransform3DIdentity
        applyTheme(from: configuration)
        applyContainerAppearance(from: configuration)

        isUserInteractionEnabled = configuration.isInteractive

        let bgView = backgroundView ?? makeBackgroundView(configuration: configuration)
        self.backgroundView = bgView
        bgView.alpha = 1
        bgView.frame = container.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let allowsBackgroundDismiss = configuration.isDismissible && configuration.dismissOnBackgroundTap
        bgView.isUserInteractionEnabled = !configuration.isPenetrable
        bgView.removeTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
        if allowsBackgroundDismiss {
            bgView.addTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
        }

        if configuration.respectsSafeArea {
            let safeAreaInsets = configuration.safeAreaInsets == .zero
                ? container.safeAreaInsets
                : configuration.safeAreaInsets
            let contentInsets = configuration.containerConfiguration.contentInsets
            layoutMargins = UIEdgeInsets(
                top: max(safeAreaInsets.top, contentInsets.top),
                left: max(safeAreaInsets.left, contentInsets.left),
                bottom: max(safeAreaInsets.bottom, contentInsets.bottom),
                right: max(safeAreaInsets.right, contentInsets.right)
            )
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

        delegate?.popupViewWillAppear(self)
        isShowing = true

        animator.display(contentView: self, backgroundView: bgView, animated: animated) { [weak self] in
            guard let self else { return }
            guard self.isShowing, !self.isDismissing else {
                completion?()
                return
            }
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

        let selector = resolvedContainerSelector(configuration: configuration)
        TFYSwiftPopupContainerManager.shared.selectBestContainer(selector: selector) { info, _ in
            if let view = info?.containerView {
                self.finishContainerResolution(view, finish: finish)
            } else if configuration.allowContainerFallback {
                self.finishContainerResolution(
                    TFYSwiftPopupContainerManagerConvenience.getCurrentWindowContainer()?.containerView,
                    finish: finish
                )
            } else {
                self.finishContainerResolution(nil, finish: finish)
            }
        }
    }

    private func resolvedContainerSelector(configuration: TFYSwiftPopupViewConfiguration) -> TFYSwiftPopupContainerSelector {
        if let customSelector = configuration.customContainerSelector {
            return customSelector
        }
        let selector = TFYSwiftDefaultPopupContainerSelector(strategy: configuration.containerSelectionStrategy)
        selector.preferWindowContainer = configuration.preferredContainerType == .window
        selector.preferCurrentViewController = configuration.preferredContainerType == .viewController
        return selector
    }

    private func finishContainerResolution(_ view: UIView?, finish: @escaping (UIView?) -> Void) {
        if Thread.isMainThread {
            finish(view)
        } else {
            DispatchQueue.main.async { finish(view) }
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
        case .default:
            break
        }
    }

    private func applyContainerAppearance(from configuration: TFYSwiftPopupViewConfiguration) {
        let containerConfig = configuration.containerConfiguration
        let themeRadius = configuration.theme == .custom ? configuration.customThemeCornerRadius : 0
        let radius = configuration.cornerRadius > 0
            ? configuration.cornerRadius
            : max(themeRadius, containerConfig.cornerRadius)
        layer.cornerRadius = radius
        layoutMargins = containerConfig.contentInsets

        if containerConfig.shadowEnabled {
            layer.masksToBounds = false
            layer.shadowColor = containerConfig.shadowColor.cgColor
            layer.shadowOpacity = containerConfig.shadowOpacity
            layer.shadowRadius = containerConfig.shadowRadius
            layer.shadowOffset = containerConfig.shadowOffset
        } else {
            layer.masksToBounds = radius > 0
            layer.shadowColor = nil
            layer.shadowOpacity = 0
            layer.shadowRadius = 0
            layer.shadowOffset = .zero
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
            pan.cancelsTouchesInView = false
            addGestureRecognizer(pan)
            dismissGestures.append(pan)
        }
        if configuration.enableSwipeToDismiss {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToDismiss(_:)))
            swipe.direction = [.left, .right, .down]
            swipe.cancelsTouchesInView = false
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

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard configuration.containerConfiguration.shadowEnabled else {
            layer.shadowPath = nil
            return
        }
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
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

        guard let container = superview else { return }
        let keyboardFrame = container.convert(frameValue.cgRectValue, from: nil)
        let popupFrame = convert(bounds, to: container)
        let offset = TFYSwiftPopupLayoutHelper.keyboardAvoidanceOffset(
            popupFrame: popupFrame,
            keyboardFrame: keyboardFrame,
            additionalOffset: config.additionalOffset,
            safeAreaBottom: config.respectSafeArea ? container.safeAreaInsets.bottom : 0
        )

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
            if originalBounds == .zero {
                originalBounds = bounds
                originalFrame = frame
            }
            let minHeight: CGFloat = 80
            let newHeight = max(minHeight, originalBounds.height - offset)
            UIView.animate(withDuration: config.animationDuration) { [weak self] in
                guard let self else { return }
                var frame = self.frame
                frame.size.height = newHeight
                if config.respectSafeArea {
                    frame.origin.y = min(frame.origin.y, container.bounds.height - newHeight - container.safeAreaInsets.bottom)
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
                if self.originalFrame != .zero {
                    self.frame = self.originalFrame
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
        backgroundView?.removeTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
    }

    private func completeDismiss(backgroundView: TFYSwiftPopupBackgroundView?, completion: (() -> Void)?) {
        backgroundView?.removeTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)
        removeFromSuperview()
        backgroundView?.removeFromSuperview()
        isShowing = false
        isDismissing = false
        animator = nil
        self.backgroundView = nil
        containerView = nil
        alpha = 1
        transform = .identity
        layer.transform = CATransform3DIdentity
        TFYSwiftPopupPriorityManager.shared.remove(popup: self)
        delegate?.popupViewDidDisappear(self)
        completion?()
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
