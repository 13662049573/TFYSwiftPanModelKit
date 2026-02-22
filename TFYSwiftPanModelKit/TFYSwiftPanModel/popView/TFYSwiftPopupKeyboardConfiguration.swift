//
//  TFYSwiftPopupKeyboardConfiguration.swift
//  TFYSwiftPanModel
//
//  弹窗键盘配置，由 OC TFYPopupKeyboardConfiguration 迁移。
//

import UIKit

/// 键盘避让模式
public enum TFYPopupKeyboardAvoidingMode: UInt {
    case transform = 0
    case constraint
    case resize
}

/// 弹窗键盘配置
public final class TFYSwiftPopupKeyboardConfiguration: NSObject, NSCopying {
    public var isEnabled = false
    public var avoidingMode: TFYPopupKeyboardAvoidingMode = .transform
    public var additionalOffset: CGFloat = 0
    public var animationDuration: TimeInterval = 0.25
    public var respectSafeArea = true

    public override init() {
        super.init()
    }

    public func validate() -> Bool {
        if additionalOffset < 0 || animationDuration < 0 { return false }
        if animationDuration > 5 || additionalOffset > 1000 { return false }
        return true
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let c = TFYSwiftPopupKeyboardConfiguration()
        c.isEnabled = isEnabled
        c.avoidingMode = avoidingMode
        c.additionalOffset = additionalOffset
        c.animationDuration = animationDuration
        c.respectSafeArea = respectSafeArea
        return c
    }
}
