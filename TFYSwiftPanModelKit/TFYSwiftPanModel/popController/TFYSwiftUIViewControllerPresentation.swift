//
//  TFYSwiftUIViewControllerPresentation.swift
//  TFYSwiftPanModel
//
//  UIViewController 展示更新扩展，由 OC UIViewController+Presentation 迁移。
//

import UIKit

extension UIViewController {

    public func panModalTransition(to state: PresentationState) {
        panPresentedVC?.transition(to: state, animated: true)
    }

    public func panModalTransition(to state: PresentationState, animated: Bool) {
        panPresentedVC?.transition(to: state, animated: animated)
    }

    public func panModalSetContentOffset(_ offset: CGPoint, animated: Bool) {
        panPresentedVC?.setScrollableContentOffset(offset, animated: animated)
    }

    public func panModalSetContentOffset(_ offset: CGPoint) {
        panModalSetContentOffset(offset, animated: true)
    }

    public func panModalSetNeedsLayoutUpdate() {
        panPresentedVC?.setNeedsLayoutUpdate()
    }

    public func panModalUpdateUserHitBehavior() {
        panPresentedVC?.updateUserHitBehavior()
    }

    public func panModalDismissAnimated(animated: Bool, completion: (() -> Void)?) {
        guard let vc = panPresentedVC else { completion?(); return }
        vc.dismiss(animated: animated, completion: completion)
    }

    public var panDimmedView: TFYSwiftDimmedView? { panPresentedVC?.backgroundView }
    public var panRootContainerView: UIView? { panPresentedVC?.containerView }
    public var panContentView: UIView? { panPresentedVC?.presentedView }
    public var panPresentationState: PresentationState { panPresentedVC?.currentPresentationState ?? .short }
}
