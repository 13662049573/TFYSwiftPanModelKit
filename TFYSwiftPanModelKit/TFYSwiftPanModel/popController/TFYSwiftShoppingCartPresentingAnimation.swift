//
//  TFYSwiftShoppingCartPresentingAnimation.swift
//  TFYSwiftPanModel
//
//  购物车风格 presenting 动画，由 OC TFYShoppingCartPresentingAnimation 迁移。
//

import UIKit

/// 购物车风格 presenting 动画
public final class TFYSwiftShoppingCartPresentingAnimation: TFYPresentingViewControllerAnimatedTransitioning {

    public func presentTransition(context: TFYPresentingViewControllerContextTransitioning) {
        guard let toVC = context.viewController(forKey: .to) else { return }
        let containerView = context.containerView
        toVC.view.frame = context.containerView.bounds
        containerView.addSubview(toVC.view)
        toVC.view.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
        UIView.animate(withDuration: context.transitionDuration, delay: 0, options: .curveEaseOut) {
            toVC.view.transform = .identity
        }
    }

    public func dismissTransition(context: TFYPresentingViewControllerContextTransitioning) {
        guard let fromVC = context.viewController(forKey: .from), let containerView = fromVC.view.superview else { return }
        UIView.animate(withDuration: context.transitionDuration, delay: 0, options: .curveEaseIn) {
            fromVC.view.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height)
        }
    }
}
