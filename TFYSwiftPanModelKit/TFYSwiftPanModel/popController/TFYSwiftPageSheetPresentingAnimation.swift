//
//  TFYSwiftPageSheetPresentingAnimation.swift
//  TFYSwiftPanModel
//
//  PageSheet 风格 presenting 动画，由 OC TFYPageSheetPresentingAnimation 迁移。
//

import UIKit

/// iOS 13+ PageSheet 风格 presenting 动画
public final class TFYSwiftPageSheetPresentingAnimation: TFYPresentingViewControllerAnimatedTransitioning {

    public func presentTransition(context: TFYPresentingViewControllerContextTransitioning) {
        guard let toVC = context.viewController(forKey: .to) else { return }
        let containerView = context.containerView
        toVC.view.frame = context.containerView.bounds
        containerView.addSubview(toVC.view)
        toVC.view.alpha = 0
        UIView.animate(withDuration: context.transitionDuration) {
            toVC.view.alpha = 1
        }
    }

    public func dismissTransition(context: TFYPresentingViewControllerContextTransitioning) {
        guard let fromVC = context.viewController(forKey: .from) else { return }
        UIView.animate(withDuration: context.transitionDuration) {
            fromVC.view.alpha = 0
        }
    }
}
