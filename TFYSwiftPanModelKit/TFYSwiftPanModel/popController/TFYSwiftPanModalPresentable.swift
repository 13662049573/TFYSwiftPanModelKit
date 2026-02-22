//
//  TFYSwiftPanModalPresentable.swift
//  TFYSwiftPanModel
//
//  PanModal 弹窗核心配置协议，由 OC TFYPanModalPresentable 迁移。
//

import UIKit

/// 弹窗展示状态（短/中/长）
@objc public enum PresentationState: Int {
    case short = 0
    case medium
    case long
}

/// 父控制器动画样式
@objc public enum PresentingViewControllerAnimationStyle: Int {
    case none = 0
    case pageSheet
    case shoppingCart
    case custom
}

/// PanModal 弹窗核心配置协议；通过扩展提供默认实现，无需实现所有方法
public protocol TFYSwiftPanModalPresentable: AnyObject {
    // MARK: - ScrollView
    func panScrollable() -> UIScrollView?
    func isPanScrollEnabled() -> Bool
    func scrollIndicatorInsets() -> UIEdgeInsets
    func showsScrollableVerticalScrollIndicator() -> Bool
    func shouldAutoSetPanScrollContentInset() -> Bool
    func allowsExtendedPanScrolling() -> Bool
    // MARK: - 偏移/位置
    func topOffset() -> CGFloat
    func shortFormHeight() -> PanModalHeight
    func mediumFormHeight() -> PanModalHeight
    func longFormHeight() -> PanModalHeight
    func originPresentationState() -> PresentationState
    // MARK: - 动画
    func springDamping() -> CGFloat
    func transitionDuration() -> TimeInterval
    func dismissalDuration() -> TimeInterval
    func transitionAnimationOptions() -> UIView.AnimationOptions
    func shouldEnableAppearanceTransition() -> Bool
    // MARK: - 背景
    func backgroundConfig() -> TFYSwiftBackgroundConfig
    // MARK: - 用户交互
    func anchorModalToLongForm() -> Bool
    func allowsTapBackgroundToDismiss() -> Bool
    func allowsDragToDismiss() -> Bool
    func allowsPullDownWhenShortState() -> Bool
    func minVerticalVelocityToTriggerDismiss() -> CGFloat
    func isUserInteractionEnabled() -> Bool
    func isHapticFeedbackEnabled() -> Bool
    func allowsTouchEventsPassingThroughTransitionView() -> Bool
    // MARK: - 边缘交互
    func allowScreenEdgeInteractive() -> Bool
    func maxAllowedDistanceToLeftScreenEdgeForPanInteraction() -> CGFloat
    func minHorizontalVelocityToTriggerScreenEdgeDismiss() -> CGFloat
    // MARK: - Presenting VC 动画
    func presentingVCAnimationStyle() -> PresentingViewControllerAnimationStyle
    func customPresentingVCAnimation() -> TFYPresentingViewControllerAnimatedTransitioning?
    // MARK: - 内容 UI
    func shouldRoundTopCorners() -> Bool
    func cornerRadius() -> CGFloat
    func contentShadow() -> TFYSwiftPanModalShadow
    func showDragIndicator() -> Bool
    func customIndicatorView() -> (UIView & TFYSwiftPanModalIndicatorProtocol)?
    // MARK: - 键盘
    func isAutoHandleKeyboardEnabled() -> Bool
    func keyboardOffsetFromInputView() -> CGFloat
    // MARK: - 防频繁点击
    func shouldPreventFrequentTapping() -> Bool
    func frequentTapPreventionInterval() -> TimeInterval
    func shouldShowFrequentTapPreventionHint() -> Bool
    func frequentTapPreventionHintText() -> String?
    func panModalFrequentTapPreventionStateChanged(isPrevented: Bool, remainingTime: TimeInterval)
    // MARK: - 拖拽手势
    func shouldRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) -> Bool
    func willRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer)
    func didRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer)
    func didEndRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer)
    func shouldPrioritizePanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) -> Bool
    func panModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer, dismissPercent: CGFloat)
    // MARK: - 状态变更
    func shouldTransition(to state: PresentationState) -> Bool
    func willTransition(to state: PresentationState)
    func didChangeTransition(to state: PresentationState)
    // MARK: - Present
    func panModalTransitionWillBegin()
    func panModalTransitionDidFinish()
    func presentedViewDidMoveToSuperView()
    // MARK: - Dismiss
    func panModalWillDismiss()
    func panModalDidDismiss()
}

// MARK: - Default Implementations
public extension TFYSwiftPanModalPresentable {
    func panScrollable() -> UIScrollView? { nil }
    func isPanScrollEnabled() -> Bool { true }
    func scrollIndicatorInsets() -> UIEdgeInsets {
        let top = shouldRoundTopCorners() ? cornerRadius() : 0
        return UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
    }
    func showsScrollableVerticalScrollIndicator() -> Bool { true }
    func shouldAutoSetPanScrollContentInset() -> Bool { true }
    func allowsExtendedPanScrolling() -> Bool { false }
    func topOffset() -> CGFloat { 21 }
    func shortFormHeight() -> PanModalHeight { longFormHeight() }
    func mediumFormHeight() -> PanModalHeight { longFormHeight() }
    func longFormHeight() -> PanModalHeight { PanModalHeight(type: .max, height: 0) }
    func originPresentationState() -> PresentationState { .short }
    func springDamping() -> CGFloat { 0.8 }
    func transitionDuration() -> TimeInterval { 0.5 }
    func dismissalDuration() -> TimeInterval { transitionDuration() }
    func transitionAnimationOptions() -> UIView.AnimationOptions {
        [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
    }
    func shouldEnableAppearanceTransition() -> Bool { true }
    func backgroundConfig() -> TFYSwiftBackgroundConfig { TFYSwiftBackgroundConfig.config(behavior: .default) }
    func anchorModalToLongForm() -> Bool { true }
    func allowsTapBackgroundToDismiss() -> Bool { true }
    func allowsDragToDismiss() -> Bool { true }
    func allowsPullDownWhenShortState() -> Bool { true }
    func minVerticalVelocityToTriggerDismiss() -> CGFloat { 300 }
    func isUserInteractionEnabled() -> Bool { true }
    func isHapticFeedbackEnabled() -> Bool { true }
    func allowsTouchEventsPassingThroughTransitionView() -> Bool { false }
    func allowScreenEdgeInteractive() -> Bool { false }
    func maxAllowedDistanceToLeftScreenEdgeForPanInteraction() -> CGFloat { 0 }
    func minHorizontalVelocityToTriggerScreenEdgeDismiss() -> CGFloat { 500 }
    func presentingVCAnimationStyle() -> PresentingViewControllerAnimationStyle { .none }
    func customPresentingVCAnimation() -> TFYPresentingViewControllerAnimatedTransitioning? { nil }
    func shouldRoundTopCorners() -> Bool { true }
    func cornerRadius() -> CGFloat { 8 }
    func contentShadow() -> TFYSwiftPanModalShadow { .none }
    func showDragIndicator() -> Bool { !allowsTouchEventsPassingThroughTransitionView() }
    func customIndicatorView() -> (UIView & TFYSwiftPanModalIndicatorProtocol)? { nil }
    func isAutoHandleKeyboardEnabled() -> Bool { true }
    func keyboardOffsetFromInputView() -> CGFloat { 5 }
    func shouldPreventFrequentTapping() -> Bool { true }
    func frequentTapPreventionInterval() -> TimeInterval { 1 }
    func shouldShowFrequentTapPreventionHint() -> Bool { false }
    func frequentTapPreventionHintText() -> String? { "请稍后再试" }
    func panModalFrequentTapPreventionStateChanged(isPrevented: Bool, remainingTime: TimeInterval) {}
    func shouldRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) -> Bool { true }
    func willRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {}
    func didRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {}
    func didEndRespondToPanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {}
    func shouldPrioritizePanModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) -> Bool { false }
    func panModalGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer, dismissPercent: CGFloat) {}
    func shouldTransition(to state: PresentationState) -> Bool { true }
    func willTransition(to state: PresentationState) {}
    func didChangeTransition(to state: PresentationState) {}
    func panModalTransitionWillBegin() {}
    func panModalTransitionDidFinish() {}
    func presentedViewDidMoveToSuperView() {}
    func panModalWillDismiss() {}
    func panModalDidDismiss() {}
}
