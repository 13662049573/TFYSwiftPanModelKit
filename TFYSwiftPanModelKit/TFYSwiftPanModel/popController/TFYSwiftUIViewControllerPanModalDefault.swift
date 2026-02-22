//
//  TFYSwiftUIViewControllerPanModalDefault.swift
//  TFYSwiftPanModel
//
//  UIViewController 的 PanModal Presentable 默认实现，由 OC UIViewController+PanModalDefault 迁移。
//

import UIKit

extension UIViewController: TFYSwiftPanModalPresentable {

    @objc open func panScrollable() -> UIScrollView? { nil }
    @objc open func isPanScrollEnabled() -> Bool { true }

    @objc open func topOffset() -> CGFloat { topLayoutOffset + 21 }

    @objc open func shortFormHeight() -> PanModalHeight { longFormHeight() }
    @objc open func mediumFormHeight() -> PanModalHeight { longFormHeight() }

    @objc open func longFormHeight() -> PanModalHeight {
        if let scroll = panScrollable(), scroll.superview != nil, scroll.window != nil {
            scroll.layoutIfNeeded()
            let h = max(scroll.contentSize.height, scroll.bounds.height)
            return PanModalHeight(type: .content, height: h)
        }
        return PanModalHeight(type: .max, height: 0)
    }

    @objc open func originPresentationState() -> PresentationState { .short }
    @objc open func springDamping() -> CGFloat { 0.8 }
    @objc open func transitionDuration() -> TimeInterval { 0.5 }
    @objc open func dismissalDuration() -> TimeInterval { transitionDuration() }
    @objc open func transitionAnimationOptions() -> UIView.AnimationOptions {
        [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
    }
    @objc open func shouldEnableAppearanceTransition() -> Bool { true }
    @objc open func backgroundConfig() -> TFYSwiftBackgroundConfig { TFYSwiftBackgroundConfig.config(behavior: .default) }

    @objc open func scrollIndicatorInsets() -> UIEdgeInsets {
        let top = shouldRoundTopCorners() ? cornerRadius() : 0
        return UIEdgeInsets(top: top, left: 0, bottom: bottomLayoutOffset, right: 0)
    }

    @objc open func showsScrollableVerticalScrollIndicator() -> Bool { true }
    @objc open func shouldAutoSetPanScrollContentInset() -> Bool { true }
    @objc open func anchorModalToLongForm() -> Bool { true }
    @objc open func allowsExtendedPanScrolling() -> Bool {
        guard let scroll = panScrollable() else { return false }
        scroll.layoutIfNeeded()
        return scroll.contentSize.height > (scroll.frame.height - bottomLayoutOffset)
    }
    @objc open func allowsDragToDismiss() -> Bool { true }
    @objc open func minVerticalVelocityToTriggerDismiss() -> CGFloat { 300 }
    @objc open func allowsTapBackgroundToDismiss() -> Bool { true }
    @objc open func allowsPullDownWhenShortState() -> Bool { true }
    @objc open func allowScreenEdgeInteractive() -> Bool { false }
    @objc open func maxAllowedDistanceToLeftScreenEdgeForPanInteraction() -> CGFloat { 0 }
    @objc open func minHorizontalVelocityToTriggerScreenEdgeDismiss() -> CGFloat { 500 }
    @objc open func presentingVCAnimationStyle() -> PresentingViewControllerAnimationStyle { .none }
    @objc open func isUserInteractionEnabled() -> Bool { true }
    @objc open func isHapticFeedbackEnabled() -> Bool { true }
    @objc open func allowsTouchEventsPassingThroughTransitionView() -> Bool { false }
    @objc open func shouldRoundTopCorners() -> Bool { true }
    @objc open func cornerRadius() -> CGFloat { 8 }
    @objc open func contentShadow() -> TFYSwiftPanModalShadow { .none }
    @objc open func showDragIndicator() -> Bool { !allowsTouchEventsPassingThroughTransitionView() }
    @objc open func isAutoHandleKeyboardEnabled() -> Bool { true }
    @objc open func keyboardOffsetFromInputView() -> CGFloat { 5 }
    @objc open func shouldPreventFrequentTapping() -> Bool { true }
    @objc open func frequentTapPreventionInterval() -> TimeInterval { 1 }
    @objc open func shouldShowFrequentTapPreventionHint() -> Bool { false }
    @objc open func frequentTapPreventionHintText() -> String? { "请稍后再试" }
}
