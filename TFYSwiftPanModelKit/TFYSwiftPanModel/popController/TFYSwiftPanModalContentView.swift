//
//  TFYSwiftPanModalContentView.swift
//  TFYSwiftPanModel
//
//  PanModal 内容视图（可独立 present/dismiss），由 OC TFYPanModalContentView 迁移。
//

import UIKit

/// PanModal 弹窗内容视图，支持独立 present/dismiss，遵循 Presentable 与布局协议
open class TFYSwiftPanModalContentView: UIView, TFYSwiftPanModalPresentable, TFYSwiftPanModalPanGestureDelegate, TFYSwiftPanModalPresentationUpdateProtocol, TFYSwiftPanModalPresentableLayoutProtocol {

    private weak var _containerView: TFYSwiftPanModalContainerView?
    /// 从 superview 链查找或直接引用
    var containerView: TFYSwiftPanModalContainerView? {
        if let c = _containerView { return c }
        var v: UIView? = superview
        while let vv = v {
            if let c = vv as? TFYSwiftPanModalContainerView { return c }
            v = vv.superview
        }
        return nil
    }

    open var topLayoutOffset: CGFloat { 0 }
    open var bottomLayoutOffset: CGFloat {
        TFYSwiftWindowHelper.safeAreaInsets.bottom
    }

    open var shortFormYPos: CGFloat {
        let shortY = topMarginFromPanModalHeight(shortFormHeight()) + topOffset()
        return max(shortY, longFormYPos)
    }

    open var mediumFormYPos: CGFloat {
        let mediumY = topMarginFromPanModalHeight(mediumFormHeight()) + topOffset()
        return max(mediumY, longFormYPos)
    }

    open var longFormYPos: CGFloat {
        let h1 = topMarginFromPanModalHeight(longFormHeight())
        let h2 = topMarginFromPanModalHeight(PanModalHeight(type: .max, height: 0))
        return max(h1, h2) + topOffset()
    }

    open var bottomYPos: CGFloat {
        if let cv = containerView { return cv.bounds.height - topOffset() }
        return bounds.height
    }

    open func topMarginFromPanModalHeight(_ panModalHeight: PanModalHeight) -> CGFloat {
        TFYSwiftPanModalLayoutHelper.topMargin(
            for: panModalHeight,
            bottomYPos: bottomYPos,
            bottomLayoutOffset: bottomLayoutOffset
        ) {
            self.layoutIfNeeded()
            let w = self.containerView?.bounds.width ?? TFYSwiftWindowHelper.screenWidth
            let targetSize = CGSize(width: w, height: UIView.layoutFittingCompressedSize.height)
            return self.systemLayoutSizeFitting(targetSize).height
        }
    }

    public func present(in view: UIView?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self, weak view] in
                self?.present(in: view)
            }
            return
        }
        var targetView = view
        if targetView == nil { targetView = TFYSwiftWindowHelper.activeWindow }
        if let old = containerView { old.removeFromSuperview(); _containerView = nil }
        guard let v = targetView else { return }
        let container = TFYSwiftPanModalContainerView(presentingView: v, contentView: self)
        _containerView = container
        container.show()
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: animated, completion: completion)
            }
            return
        }
        guard let cv = containerView else { completion?(); return }
        cv.dismiss(animated: animated, completion: { [weak self] in
            completion?()
            self?._containerView = nil
        })
    }

    // MARK: - TFYSwiftPanModalPresentationUpdateProtocol（未 present 时为 nil）
    public var panDimmedView: TFYSwiftDimmedView? { containerView?.backgroundView }
    public var panRootContainerView: UIView? { containerView }
    public var panContentView: UIView? { containerView?.panContainerView }
    public var panPresentationState: PresentationState { containerView?.currentPresentationState ?? .short }

    public func panModalTransition(to state: PresentationState) { containerView?.transition(to: state, animated: true) }
    public func panModalTransition(to state: PresentationState, animated: Bool) { containerView?.transition(to: state, animated: animated) }
    public func panModalSetContentOffset(_ offset: CGPoint) { containerView?.setScrollableContentOffset(offset, animated: true) }
    public func panModalSetContentOffset(_ offset: CGPoint, animated: Bool) { containerView?.setScrollableContentOffset(offset, animated: animated) }
    public func panModalSetNeedsLayoutUpdate() { containerView?.setNeedsLayoutUpdate() }
    public func panModalUpdateUserHitBehavior() { containerView?.updateUserHitBehavior() }
    public func panModalDismissAnimated(animated: Bool, completion: (() -> Void)?) { dismiss(animated: animated, completion: completion) }

    // MARK: - TFYSwiftPanModalPresentable 默认实现
    open func panScrollable() -> UIScrollView? { nil }
    open func isPanScrollEnabled() -> Bool { true }
    open func scrollIndicatorInsets() -> UIEdgeInsets {
        UIEdgeInsets(top: shouldRoundTopCorners() ? cornerRadius() : 0, left: 0, bottom: bottomLayoutOffset, right: 0)
    }
    open func showsScrollableVerticalScrollIndicator() -> Bool { true }
    open func shouldAutoSetPanScrollContentInset() -> Bool { true }
    open func allowsExtendedPanScrolling() -> Bool {
        guard let scroll = panScrollable(), scroll.superview != nil, scroll.window != nil else { return false }
        scroll.layoutIfNeeded()
        return scroll.contentSize.height > scroll.frame.height - bottomLayoutOffset
    }
    open func topOffset() -> CGFloat { topLayoutOffset + 21 }
    open func shortFormHeight() -> PanModalHeight { longFormHeight() }
    open func mediumFormHeight() -> PanModalHeight { longFormHeight() }
    open func longFormHeight() -> PanModalHeight {
        if let scroll = panScrollable() {
            scroll.layoutIfNeeded()
            let h = max(scroll.contentSize.height, scroll.bounds.height)
            return PanModalHeight(type: .content, height: h)
        }
        return PanModalHeight(type: .max, height: 0)
    }
    open func originPresentationState() -> PresentationState { .short }
    open func springDamping() -> CGFloat { 0.8 }
    open func transitionDuration() -> TimeInterval { 0.5 }
    open func dismissalDuration() -> TimeInterval { transitionDuration() }
    open func transitionAnimationOptions() -> UIView.AnimationOptions { [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState] }
    open func shouldEnableAppearanceTransition() -> Bool { true }
    open func backgroundConfig() -> TFYSwiftBackgroundConfig { TFYSwiftBackgroundConfig.config(behavior: .default) }
    open func anchorModalToLongForm() -> Bool { true }
    open func allowsTapBackgroundToDismiss() -> Bool { true }
    open func allowsDragToDismiss() -> Bool { true }
    open func allowsPullDownWhenShortState() -> Bool { true }
    open func minVerticalVelocityToTriggerDismiss() -> CGFloat { 300 }
    open func isUserInteractionEnabled() -> Bool { true }
    open func isHapticFeedbackEnabled() -> Bool { true }
    open func allowsTouchEventsPassingThroughTransitionView() -> Bool { false }
    open func allowScreenEdgeInteractive() -> Bool { false }
    open func maxAllowedDistanceToLeftScreenEdgeForPanInteraction() -> CGFloat { 0 }
    open func minHorizontalVelocityToTriggerScreenEdgeDismiss() -> CGFloat { 500 }
    open func presentingVCAnimationStyle() -> PresentingViewControllerAnimationStyle { .none }
    open func customPresentingVCAnimation() -> TFYPresentingViewControllerAnimatedTransitioning? { nil }
    open func shouldRoundTopCorners() -> Bool { true }
    open func cornerRadius() -> CGFloat { 8 }
    open func contentShadow() -> TFYSwiftPanModalShadow { .none }
    open func showDragIndicator() -> Bool { !allowsTouchEventsPassingThroughTransitionView() }
    open func customIndicatorView() -> (UIView & TFYSwiftPanModalIndicatorProtocol)? { nil }
    open func isAutoHandleKeyboardEnabled() -> Bool { true }
    open func keyboardOffsetFromInputView() -> CGFloat { 5 }
    open func shouldPreventFrequentTapping() -> Bool { true }
    open func frequentTapPreventionInterval() -> TimeInterval { 1 }
    open func shouldShowFrequentTapPreventionHint() -> Bool { false }
    open func frequentTapPreventionHintText() -> String? { "请稍后再试" }
    open func panModalFrequentTapPreventionStateChanged(isPrevented: Bool, remainingTime: TimeInterval) {}
    open func shouldRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) -> Bool { true }
    open func willRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {}
    open func didRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {}
    open func didEndRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {}
    open func shouldPrioritizePanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) -> Bool { false }
    open func panModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer, dismissPercent: CGFloat) {}
    open func shouldTransition(to state: PresentationState) -> Bool { true }
    open func willTransition(to state: PresentationState) {}
    open func didChangeTransition(to state: PresentationState) {}
    open func panModalTransitionWillBegin() {}
    open func panModalTransitionDidFinish() {}
    open func presentedViewDidMoveToSuperView() {}
    open func panModalWillDismiss() {}
    open func panModalDidDismiss() {}

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        _containerView?.removeFromSuperview()
    }
}
