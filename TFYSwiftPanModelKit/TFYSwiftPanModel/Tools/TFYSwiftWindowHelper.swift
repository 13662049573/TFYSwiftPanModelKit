//
//  TFYSwiftWindowHelper.swift
//  TFYSwiftPanModel
//
//  全局窗口/安全区域工具，消除重复的 scene 遍历代码
//

import UIKit

public enum TFYSwiftWindowHelper {

    /// 当前活跃的 key window
    public static var activeWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first { $0.isKeyWindow }
    }

    /// 当前安全区域 insets
    public static var safeAreaInsets: UIEdgeInsets {
        activeWindow?.safeAreaInsets ?? .zero
    }

    /// 屏幕宽度（基于 window scene，避免 UIScreen.main 废弃警告）
    public static var screenWidth: CGFloat {
        activeWindow?.bounds.width ?? 0
    }

    /// 屏幕高度
    public static var screenHeight: CGFloat {
        activeWindow?.bounds.height ?? 0
    }
}

// MARK: - CGFloat 浮点比较扩展

public extension CGFloat {

    /// 是否近似为 0
    var isNearZero: Bool {
        self > -CGFloat(Float.ulpOfOne) && self < CGFloat(Float.ulpOfOne)
    }

    /// 是否与另一个值近似相等
    func isNearlyEqual(to other: CGFloat) -> Bool {
        let diff = abs(self - other)
        return diff < 0.0001 || diff < CGFloat(Float.leastNormalMagnitude)
    }
}
