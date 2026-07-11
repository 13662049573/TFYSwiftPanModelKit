//
//  TFYSwiftPresentingViewControllerContext.swift
//  TFYSwiftPanModel
//
//  Presenting VC 自定义转场上下文实现
//

import UIKit

/// Presenting VC 转场上下文实现
public final class TFYSwiftPresentingViewControllerContext: TFYPresentingViewControllerContextTransitioning {

    public let containerView: UIView
    public let transitionDuration: TimeInterval
    private let viewControllers: [UITransitionContextViewControllerKey: UIViewController]

    public init(
        containerView: UIView,
        presenting: UIViewController,
        presented: UIViewController,
        duration: TimeInterval
    ) {
        self.containerView = containerView
        self.transitionDuration = duration
        self.viewControllers = [
            .from: presenting,
            .to: presented
        ]
    }

    public func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        viewControllers[key]
    }
}
