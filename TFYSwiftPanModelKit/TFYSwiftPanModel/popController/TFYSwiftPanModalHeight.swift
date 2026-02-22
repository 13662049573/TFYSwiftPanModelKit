//
//  TFYSwiftPanModalHeight.swift
//  TFYSwiftPanModel
//
//  弹窗高度类型与结构
//

import UIKit

/// 弹窗高度类型
@objc public enum PanModalHeightType: Int {
    case max = 0
    case topInset
    case content
    case contentIgnoringSafeArea
    case intrinsic
}

/// 弹窗高度配置（NSObject 子类以支持 @objc 方法返回值）
public final class PanModalHeight: NSObject {
    public var type: PanModalHeightType
    public var height: CGFloat

    public init(type: PanModalHeightType, height: CGFloat = 0) {
        self.type = type
        self.height = height
        super.init()
    }
}

// MARK: - 旧函数兼容别名（已迁移到 CGFloat 扩展，后续可移除）

@available(*, deprecated, renamed: "CGFloat.isNearZero")
public func TFY_FLOAT_IS_ZERO(_ value: CGFloat) -> Bool {
    value.isNearZero
}

@available(*, deprecated, renamed: "CGFloat.isNearlyEqual(to:)")
public func TFY_TWO_FLOAT_IS_EQUAL(_ x: CGFloat, _ y: CGFloat) -> Bool {
    x.isNearlyEqual(to: y)
}
