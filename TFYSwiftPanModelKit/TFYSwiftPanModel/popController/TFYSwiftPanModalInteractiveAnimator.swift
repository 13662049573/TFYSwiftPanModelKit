//
//  TFYSwiftPanModalInteractiveAnimator.swift
//  TFYSwiftPanModel
//
//  PanModal 手势交互动画控制器，由 OC TFYPanModalInteractiveAnimator 迁移。
//

import UIKit

/// PanModal 手势驱动 dismiss 交互动画
public final class TFYSwiftPanModalInteractiveAnimator: UIPercentDrivenInteractiveTransition {

    public override var completionSpeed: CGFloat {
        get {
            let speed: CGFloat = 0.618
            return max(0.1, min(1.0, speed))
        }
        set { }
    }
}
