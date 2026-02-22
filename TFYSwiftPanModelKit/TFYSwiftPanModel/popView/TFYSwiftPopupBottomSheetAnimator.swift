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
    public var maximumHeight: CGFloat = TFYSwiftWindowHelper.screenHeight
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
    private var initialTouchPoint: CGPoint = .zero
    private var heightConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?

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
        contentView.layer.cornerRadius = configuration.cornerRadius
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
        let clampedDefault = min(max(configuration.defaultHeight, configuration.minimumHeight), configuration.maximumHeight)
        if hc.constant <= 0 {
            hc.constant = clampedDefault
        } else {
            hc.constant = min(max(hc.constant, configuration.minimumHeight), configuration.maximumHeight)
        }
    }

    public func display(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void) {
        guard let pv = popupView, let bc = bottomConstraint, let hc = heightConstraint else {
            completion()
            return
        }
        let layoutTarget = pv.superview ?? pv
        bc.constant = configuration.defaultHeight
        hc.constant = configuration.defaultHeight
        backgroundView.alpha = 0
        layoutTarget.layoutIfNeeded()
        if animated {
            UIView.animate(withDuration: configuration.animationDuration, delay: 0, usingSpringWithDamping: configuration.springDamping, initialSpringVelocity: configuration.springVelocity, options: .curveEaseOut) {
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
            UIView.animate(withDuration: configuration.animationDuration, delay: 0, options: .curveEaseIn) {
                bc.constant = self.configuration.defaultHeight
                backgroundView.alpha = 0
                layoutTarget.layoutIfNeeded()
            } completion: { _ in completion() }
        } else {
            bc.constant = configuration.defaultHeight
            backgroundView.alpha = 0
            layoutTarget.layoutIfNeeded()
            completion()
        }
    }

    // MARK: - Layout & Gesture

    private func setupLayout(popupView: TFYSwiftPopupView, contentView: UIView) {
        let anchorView: UIView = contentView.superview ?? popupView
        let hc = contentView.heightAnchor.constraint(equalToConstant: configuration.defaultHeight)
        let bc = contentView.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor, constant: configuration.defaultHeight)
        heightConstraint = hc
        bottomConstraint = bc
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: anchorView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: anchorView.trailingAnchor),
            bc, hc,
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: configuration.minimumHeight),
            contentView.heightAnchor.constraint(lessThanOrEqualToConstant: configuration.maximumHeight)
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
            initialTouchPoint = gesture.location(in: pv)
            currentHeight = hc.constant
        case .changed:
            let dragOffset = translation.y
            if dragOffset < 0 {
                let newHeight = min(currentHeight - dragOffset, configuration.maximumHeight)
                hc.constant = newHeight
                bc.constant = 0
            } else {
                if currentHeight > configuration.defaultHeight {
                    let newHeight = max(currentHeight - dragOffset, configuration.defaultHeight)
                    hc.constant = newHeight
                    bc.constant = 0
                } else {
                    let newOffset = min(dragOffset, configuration.defaultHeight)
                    bc.constant = newOffset
                    hc.constant = configuration.defaultHeight
                }
            }
            (pv.superview ?? pv).layoutIfNeeded()
        case .ended, .cancelled:
            isDragging = false
            let currentOffset = bc.constant
            let currentHeightValue = hc.constant
            if currentOffset > configuration.minimumHeight || velocity.y > 500 {
                pv.dismissAnimated(true, completion: nil)
                return
            }
            if velocity.y < -500 && configuration.allowsFullScreen {
                animateToHeight(configuration.maximumHeight, popupView: pv)
            } else if currentHeightValue > configuration.defaultHeight + configuration.snapToDefaultThreshold {
                animateToHeight(configuration.maximumHeight, popupView: pv)
            } else {
                animateToHeight(configuration.defaultHeight, popupView: pv)
            }
        default:
            break
        }
    }

    private func animateToHeight(_ height: CGFloat, popupView pv: TFYSwiftPopupView) {
        guard let hc = heightConstraint, let bc = bottomConstraint else { return }
        let layoutTarget = pv.superview ?? pv
        UIView.animate(withDuration: configuration.animationDuration, delay: 0, usingSpringWithDamping: configuration.springDamping, initialSpringVelocity: configuration.springVelocity, options: .curveEaseOut) {
            hc.constant = height
            bc.constant = 0
            layoutTarget.layoutIfNeeded()
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        other.view is UIScrollView
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
        false
    }
}
