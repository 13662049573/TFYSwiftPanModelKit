//
//  TFYSwiftPanModalPresentationDelegate.swift
//  TFYSwiftPanModel
//
//  PanModal 转场代理，由 OC TFYPanModalPresentationDelegate 迁移。
//

import UIKit

/// PanModal 转场代理，负责 present/dismiss 动画与交互
public final class TFYSwiftPanModalPresentationDelegate: NSObject,
    UIViewControllerTransitioningDelegate,
    UIAdaptivePresentationControllerDelegate,
    UIPopoverPresentationControllerDelegate {

    public var interactive: Bool = false
    public var interactiveMode: PanModalInteractiveMode = .none
    public private(set) lazy var interactiveDismissalAnimator: TFYSwiftPanModalInteractiveAnimator = {
        TFYSwiftPanModalInteractiveAnimator()
    }()
    public var strongPresentationController: TFYSwiftPanModalPresentationController?

    // MARK: - UIViewControllerTransitioningDelegate
    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        TFYSwiftPanModalPresentationAnimator(transitionStyle: .presentation, interactiveMode: .none)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        TFYSwiftPanModalPresentationAnimator(transitionStyle: .dismissal, interactiveMode: interactiveMode)
    }

    public func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        interactive ? interactiveDismissalAnimator : nil
    }

    public func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let controller = TFYSwiftPanModalPresentationController(
            presentedViewController: presented,
            presenting: presenting ?? source
        )
        controller.presentationDelegate = self
        strongPresentationController = controller
        return controller
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    public func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }
}
