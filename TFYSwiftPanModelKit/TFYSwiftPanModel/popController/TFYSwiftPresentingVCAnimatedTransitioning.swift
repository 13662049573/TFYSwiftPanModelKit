//
//  TFYSwiftPresentingVCAnimatedTransitioning.swift
//  TFYSwiftPanModel
//
//  自定义 present 转场上下文与动画协议，由 OC TFYPresentingVCAnimatedTransitioning 迁移。
//

import UIKit

/// 自定义转场动画上下文协议
public protocol TFYPresentingViewControllerContextTransitioning: AnyObject {
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController?
    var transitionDuration: TimeInterval { get }
    var containerView: UIView { get }
}

/// 自定义 present/dismiss 动画协议
public protocol TFYPresentingViewControllerAnimatedTransitioning: AnyObject {
    func presentTransition(context: TFYPresentingViewControllerContextTransitioning)
    func dismissTransition(context: TFYPresentingViewControllerContextTransitioning)
}
