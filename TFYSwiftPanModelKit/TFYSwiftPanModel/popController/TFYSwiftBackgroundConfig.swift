//
//  TFYSwiftBackgroundConfig.swift
//  TFYSwiftPanModel
//
//  PanModal 背景配置，由 OC TFYBackgroundConfig 迁移。
//

import UIKit

/// 背景遮罩显示模式
public enum TFYBackgroundBehavior: UInt {
    case `default` = 0
    case systemVisualEffect
    case customBlurEffect
}

/// PanModal 弹窗背景配置
public final class TFYSwiftBackgroundConfig: NSObject {
    public var backgroundBehavior: TFYBackgroundBehavior {
        didSet { applyBehavior(backgroundBehavior) }
    }
    public var backgroundAlpha: CGFloat = 0.7
    public var visualEffect: UIVisualEffect?
    public var blurTintColor: UIColor?
    public var backgroundBlurRadius: CGFloat = 10

    public override init() {
        self.backgroundBehavior = .default
        super.init()
        applyBehavior(.default)
    }

    public init(behavior: TFYBackgroundBehavior) {
        self.backgroundBehavior = behavior
        super.init()
        applyBehavior(behavior)
    }

    public static func config(behavior: TFYBackgroundBehavior) -> TFYSwiftBackgroundConfig {
        TFYSwiftBackgroundConfig(behavior: behavior)
    }

    private func applyBehavior(_ behavior: TFYBackgroundBehavior) {
        switch behavior {
        case .systemVisualEffect:
            visualEffect = UIBlurEffect(style: .systemMaterial)
            backgroundAlpha = 0.7
        case .customBlurEffect:
            backgroundBlurRadius = 10
            blurTintColor = UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(white: 0.1, alpha: 0.7)
                    : .white
            }
            backgroundAlpha = 0.7
        case .default:
            backgroundAlpha = 0.7
        }
    }
}
