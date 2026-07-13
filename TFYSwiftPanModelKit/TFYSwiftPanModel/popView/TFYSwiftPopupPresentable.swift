//
//  TFYSwiftPopupPresentable.swift
//  TFYSwiftPanModel
//
//  UIViewController 作为 PopupView 内容时的可配置协议。
//

import UIKit

/// 可被 PopupView 体系弹出的控制器配置协议
///
/// 任意 `UIViewController` 默认已遵循；在子类中 override 对应 `@objc open` 方法即可自定义。
public protocol TFYSwiftPopupPresentable: AnyObject {
    /// 弹窗内容首选尺寸；宽或高为 0 时由布局/Auto Layout 决定
    func popupPreferredContentSize() -> CGSize
    /// 弹窗配置（背景、关闭、优先级等）
    func popupConfiguration() -> TFYSwiftPopupViewConfiguration
    /// 首选动画器；返回 nil 时使用默认 Spring + 居中布局
    func popupPreferredAnimator() -> TFYSwiftPopupViewAnimator?
    /// 首选布局；返回 nil 时根据 `popupPreferredContentSize()` 生成居中布局
    func popupPreferredLayout() -> TFYSwiftPopupAnimatorLayout?
    /// 是否允许关闭（背景点击 / 手势 / 代码关闭前询问）
    func popupShouldDismiss() -> Bool
    func popupWillAppear()
    func popupDidAppear()
    func popupWillDisappear()
    func popupDidDisappear()
}
