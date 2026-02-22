//
//  TFYSwiftPanModalAnimator.swift
//  TFYSwiftPanModel
//
//  PanModal 弹窗动画工具类
//

import UIKit

/// 旧名兼容（已迁移到 TFYSwiftPanModalAnimator.defaultDuration）
public let kTransitionDuration: TimeInterval = 0.5

/// PanModal 弹窗动画工具
public enum TFYSwiftPanModalAnimator {

    /// 默认转场时长
    public static let defaultDuration: TimeInterval = 0.5

    public static func animate(
        _ animations: @escaping () -> Void,
        config: TFYSwiftPanModalPresentable?,
        completion: ((Bool) -> Void)?
    ) {
        animate(animations, config: config, startingFromPercent: 1, isPresentation: true, completion: completion)
    }

    public static func dismissAnimate(
        _ animations: @escaping () -> Void,
        config: TFYSwiftPanModalPresentable?,
        completion: ((Bool) -> Void)?
    ) {
        animate(animations, config: config, startingFromPercent: 1, isPresentation: false, completion: completion)
    }

    public static func animate(
        _ animations: @escaping () -> Void,
        config: TFYSwiftPanModalPresentable?,
        startingFromPercent animationPercent: CGFloat,
        isPresentation: Bool,
        completion: ((Bool) -> Void)?
    ) {
        let duration = isPresentation
            ? (config?.transitionDuration() ?? defaultDuration)
            : (config?.dismissalDuration() ?? defaultDuration)
        let d = duration * max(animationPercent, 0)
        let springDamping = config?.springDamping() ?? 1.0
        let options = config?.transitionAnimationOptions() ?? .curveEaseInOut
        UIView.animate(withDuration: d, delay: 0, usingSpringWithDamping: springDamping,
                       initialSpringVelocity: 0, options: options,
                       animations: animations, completion: completion)
    }

    public static func smoothAnimate(
        _ animations: @escaping () -> Void,
        duration: TimeInterval,
        completion: ((Bool) -> Void)?
    ) {
        UIView.animate(withDuration: duration, delay: 0, options: .curveLinear,
                       animations: animations, completion: completion)
    }
}
