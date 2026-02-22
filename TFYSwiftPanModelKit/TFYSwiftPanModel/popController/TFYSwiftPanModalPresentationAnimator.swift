//
//  TFYSwiftPanModalPresentationAnimator.swift
//  TFYSwiftPanModel
//
//  PanModal 转场动画器 — 从底部滑入、滑出到底部
//

import UIKit

/// 转场类型
public enum TransitionStyle: Int {
    case presentation = 0
    case dismissal
}

/// 交互模式
public enum PanModalInteractiveMode: Int {
    case none = 0
    case sideslip
    case dragDown
}

/// PanModal 转场动画（VC 路径）
///
/// presentation: presentedView 从屏幕底部滑入到当前 frame.origin.y（由 PresentationController 在 willBegin 中设好）
/// dismissal:    presentedView 从当前位置滑出到屏幕底部
public final class TFYSwiftPanModalPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let transitionStyle: TransitionStyle
    private let interactiveMode: PanModalInteractiveMode

    public init(transitionStyle: TransitionStyle, interactiveMode: PanModalInteractiveMode) {
        self.transitionStyle = transitionStyle
        self.interactiveMode = interactiveMode
        super.init()
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        let key: UITransitionContextViewControllerKey = transitionStyle == .presentation ? .to : .from
        guard let vc = transitionContext?.viewController(forKey: key) else { return kTransitionDuration }
        return transitionStyle == .presentation ? vc.transitionDuration() : vc.dismissalDuration()
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if transitionStyle == .presentation {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using ctx: UIViewControllerContextTransitioning) {
        guard let toVC = ctx.viewController(forKey: .to) else {
            ctx.completeTransition(false)
            return
        }

        // presentedView 可能是 PanContainerView（由 PresentationController 返回）
        let presentedView: UIView
        if let pv = ctx.view(forKey: .to) {
            presentedView = pv
        } else {
            presentedView = toVC.view
        }

        let containerView = ctx.containerView
        containerView.addSubview(presentedView)

        // PresentationController 已经设定了 panContainerView.frame = containerView.bounds
        // 此时 presentedView（panContainerView）的 frame 是全屏
        // 我们需要把它从屏幕底部滑入
        let targetY = presentedView.frame.origin.y
        presentedView.frame.origin.y = containerView.bounds.height

        TFYSwiftPanModalAnimator.animate({
            presentedView.frame.origin.y = targetY
        }, config: toVC) { _ in
            ctx.completeTransition(!ctx.transitionWasCancelled)
        }
    }

    private func animateDismissal(using ctx: UIViewControllerContextTransitioning) {
        guard let fromVC = ctx.viewController(forKey: .from) else {
            ctx.completeTransition(false)
            return
        }

        let presentedView: UIView
        if let pv = ctx.view(forKey: .from) {
            presentedView = pv
        } else {
            presentedView = fromVC.view
        }

        let containerView = ctx.containerView

        TFYSwiftPanModalAnimator.dismissAnimate({
            presentedView.frame.origin.y = containerView.bounds.height
        }, config: fromVC) { _ in
            ctx.completeTransition(!ctx.transitionWasCancelled)
        }
    }
}
