//
//  TFYSwiftPopupBottomSheetAnimator.swift
//  TFYSwiftPanModel
//
//  底部弹出框动画器与配置，由 OC TFYPopupBottomSheetAnimator 迁移。
//

import UIKit

/// 底部弹出框配置
public final class TFYSwiftPopupBottomSheetConfiguration: NSObject, NSCopying {
    public var defaultHeight: CGFloat = 300
    public var minimumHeight: CGFloat = 100
    /// 0 表示展示时使用实际容器高度，适配多窗口和启动早期尚无 key window 的场景。
    public var maximumHeight: CGFloat = 0
    public var allowsFullScreen = true
    public var snapToDefaultThreshold: CGFloat = 80
    public var springDamping: CGFloat = 0.8
    public var springVelocity: CGFloat = 0.4
    public var animationDuration: TimeInterval = 0.35
    public var cornerRadius: CGFloat = 10
    public var enableGestures = false

    public override init() {
        super.init()
    }

    public func validate() -> Bool {
        let values = [defaultHeight, minimumHeight, maximumHeight, snapToDefaultThreshold,
                      springDamping, springVelocity, CGFloat(animationDuration), cornerRadius]
        guard values.allSatisfy({ $0.isFinite }) else { return false }
        guard defaultHeight >= 0, minimumHeight >= 0, maximumHeight >= 0,
              snapToDefaultThreshold >= 0, springDamping >= 0, springDamping <= 1,
              springVelocity >= 0, animationDuration >= 0, cornerRadius >= 0 else { return false }
        return maximumHeight == 0 || minimumHeight <= maximumHeight
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupBottomSheetConfiguration()
        c.defaultHeight = defaultHeight
        c.minimumHeight = minimumHeight
        c.maximumHeight = maximumHeight
        c.allowsFullScreen = allowsFullScreen
        c.snapToDefaultThreshold = snapToDefaultThreshold
        c.springDamping = springDamping
        c.springVelocity = springVelocity
        c.animationDuration = animationDuration
        c.cornerRadius = cornerRadius
        c.enableGestures = enableGestures
        return c
    }
}

/// 底部弹出框动画器
public final class TFYSwiftPopupBottomSheetAnimator: NSObject, TFYSwiftPopupViewAnimator, UIGestureRecognizerDelegate {
    private(set) public var configuration: TFYSwiftPopupBottomSheetConfiguration
    private weak var popupView: TFYSwiftPopupView?
    private weak var contentView: UIView?
    private weak var backgroundView: TFYSwiftPopupBackgroundView?
    private var panGesture: UIPanGestureRecognizer?
    private var currentHeight: CGFloat = 0
    private var isDragging = false
    private var heightConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var resolvedMinimumHeight: CGFloat = 0
    private var resolvedDefaultHeight: CGFloat = 0
    private var resolvedMaximumHeight: CGFloat = 0

    public init(configuration: TFYSwiftPopupBottomSheetConfiguration) {
        guard let copied = configuration.copy(with: nil) as? TFYSwiftPopupBottomSheetConfiguration else {
            self.configuration = TFYSwiftPopupBottomSheetConfiguration()
            super.init()
            return
        }
        self.configuration = copied
        super.init()
    }

    public override init() {
        self.configuration = TFYSwiftPopupBottomSheetConfiguration()
        super.init()
    }

    public var isGesturesEnabled: Bool { panGesture != nil }

    public func enableGestures() {
        guard let cv = contentView else { return }
        if let pan = panGesture { cv.removeGestureRecognizer(pan) }
        addPanGesture(to: cv)
    }

    public func disableGestures() {
        guard let cv = contentView, let pan = panGesture else { return }
        cv.removeGestureRecognizer(pan)
        panGesture = nil
    }

    // MARK: - TFYSwiftPopupViewAnimator

    public func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        self.popupView = popupView
        self.contentView = contentView
        self.backgroundView = backgroundView
        contentView.layer.cornerRadius = finiteNonnegative(configuration.cornerRadius)
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.clipsToBounds = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        setupLayout(popupView: popupView, contentView: contentView)
        if configuration.enableGestures {
            addPanGesture(to: contentView)
        }
    }

    public func refreshLayout(popupView: TFYSwiftPopupView, contentView: UIView) {
        guard let hc = heightConstraint, !isDragging else { return }
        resolveHeights(in: contentView.superview ?? popupView)
        if hc.constant <= 0 {
            hc.constant = resolvedDefaultHeight
        } else {
            hc.constant = min(max(hc.constant, resolvedMinimumHeight), resolvedMaximumHeight)
        }
    }

    public func display(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void) {
        guard let pv = popupView, let bc = bottomConstraint, let hc = heightConstraint else {
            completion()
            return
        }
        let layoutTarget = pv.superview ?? pv
        bc.constant = resolvedDefaultHeight
        hc.constant = resolvedDefaultHeight
        backgroundView.alpha = 0
        layoutTarget.layoutIfNeeded()
        if animated {
            UIView.animate(withDuration: resolvedAnimationDuration, delay: 0, usingSpringWithDamping: resolvedSpringDamping, initialSpringVelocity: resolvedSpringVelocity, options: .curveEaseOut) {
                bc.constant = 0
                backgroundView.alpha = 1
                layoutTarget.layoutIfNeeded()
            } completion: { _ in completion() }
        } else {
            bc.constant = 0
            backgroundView.alpha = 1
            layoutTarget.layoutIfNeeded()
            completion()
        }
    }

    public func dismiss(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void) {
        guard let pv = popupView, let bc = bottomConstraint else {
            completion()
            return
        }
        let layoutTarget = pv.superview ?? pv
        if animated {
            UIView.animate(withDuration: resolvedAnimationDuration, delay: 0, options: .curveEaseIn) {
                bc.constant = self.resolvedDefaultHeight
                backgroundView.alpha = 0
                layoutTarget.layoutIfNeeded()
            } completion: { _ in completion() }
        } else {
            bc.constant = resolvedDefaultHeight
            backgroundView.alpha = 0
            layoutTarget.layoutIfNeeded()
            completion()
        }
    }

    // MARK: - Layout & Gesture

    private func setupLayout(popupView: TFYSwiftPopupView, contentView: UIView) {
        let anchorView: UIView = contentView.superview ?? popupView
        resolveHeights(in: anchorView)
        let hc = contentView.heightAnchor.constraint(equalToConstant: resolvedDefaultHeight)
        let bc = contentView.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor, constant: resolvedDefaultHeight)
        heightConstraint = hc
        bottomConstraint = bc
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: anchorView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: anchorView.trailingAnchor),
            bc, hc,
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: resolvedMinimumHeight),
            contentView.heightAnchor.constraint(lessThanOrEqualToConstant: resolvedMaximumHeight)
        ])
        hc.priority = .defaultHigh
        bc.priority = .required
    }

    private func addPanGesture(to view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        panGesture = pan
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let pv = popupView, let hc = heightConstraint, let bc = bottomConstraint else { return }
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in self?.handlePan(gesture) }
            return
        }
        let translation = gesture.translation(in: pv)
        let velocity = gesture.velocity(in: pv)
        switch gesture.state {
        case .began:
            isDragging = true
            currentHeight = hc.constant
        case .changed:
            let dragOffset = translation.y
            if dragOffset < 0 {
                let newHeight = min(currentHeight - dragOffset, resolvedMaximumHeight)
                hc.constant = newHeight
                bc.constant = 0
            } else {
                if currentHeight > resolvedDefaultHeight {
                    let newHeight = max(currentHeight - dragOffset, resolvedDefaultHeight)
                    hc.constant = newHeight
                    bc.constant = 0
                } else {
                    let newOffset = min(dragOffset, resolvedDefaultHeight)
                    bc.constant = newOffset
                    hc.constant = resolvedDefaultHeight
                }
            }
            pv.setNeedsLayout()
            pv.layoutIfNeeded()
        case .ended, .cancelled:
            isDragging = false
            let currentOffset = bc.constant
            let currentHeightValue = hc.constant
            if currentOffset > resolvedMinimumHeight || velocity.y > 500 {
                pv.dismissAnimated(true, completion: nil)
                return
            }
            if velocity.y < -500 && configuration.allowsFullScreen {
                animateToHeight(resolvedMaximumHeight, popupView: pv)
            } else if currentHeightValue > resolvedDefaultHeight + finiteNonnegative(configuration.snapToDefaultThreshold) {
                animateToHeight(resolvedMaximumHeight, popupView: pv)
            } else {
                animateToHeight(resolvedDefaultHeight, popupView: pv)
            }
        default:
            break
        }
    }

    private func animateToHeight(_ height: CGFloat, popupView pv: TFYSwiftPopupView) {
        guard let hc = heightConstraint, let bc = bottomConstraint else { return }
        let layoutTarget = pv.superview ?? pv
        UIView.animate(withDuration: resolvedAnimationDuration, delay: 0, usingSpringWithDamping: resolvedSpringDamping, initialSpringVelocity: resolvedSpringVelocity, options: .curveEaseOut) {
            hc.constant = height
            bc.constant = 0
            layoutTarget.layoutIfNeeded()
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
              let contentView else { return true }
        let velocity = pan.velocity(in: contentView)
        guard abs(velocity.y) > abs(velocity.x) else { return false }

        var touchedView = contentView.hitTest(pan.location(in: contentView), with: nil)
        while let view = touchedView {
            if let scrollView = view as? UIScrollView {
                let top = -scrollView.adjustedContentInset.top
                if velocity.y > 0, scrollView.contentOffset.y > top + 0.5 { return false }
                if velocity.y < 0, (heightConstraint?.constant ?? resolvedDefaultHeight) >= resolvedMaximumHeight - 0.5 { return false }
                break
            }
            touchedView = view.superview
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        other.view is UIScrollView
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
        false
    }

    private func resolveHeights(in container: UIView) {
        let configuredDefault = finiteNonnegative(configuration.defaultHeight)
        let configuredMinimum = finiteNonnegative(configuration.minimumHeight)
        let fallback = max(max(configuredDefault, configuredMinimum), 1)
        let available = container.bounds.height.isFinite && container.bounds.height > 0
            ? container.bounds.height
            : max(TFYSwiftWindowHelper.screenHeight, fallback)
        let configuredMaximum = finiteNonnegative(configuration.maximumHeight)
        resolvedMaximumHeight = configuredMaximum > 0 ? min(configuredMaximum, available) : available
        resolvedMinimumHeight = min(configuredMinimum, resolvedMaximumHeight)
        resolvedDefaultHeight = min(max(configuredDefault, resolvedMinimumHeight), resolvedMaximumHeight)
    }

    private func finiteNonnegative(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(0, value) : 0
    }

    private var resolvedAnimationDuration: TimeInterval {
        configuration.animationDuration.isFinite ? max(0, configuration.animationDuration) : 0.35
    }

    private var resolvedSpringDamping: CGFloat {
        min(1, finiteNonnegative(configuration.springDamping))
    }

    private var resolvedSpringVelocity: CGFloat {
        finiteNonnegative(configuration.springVelocity)
    }
}
