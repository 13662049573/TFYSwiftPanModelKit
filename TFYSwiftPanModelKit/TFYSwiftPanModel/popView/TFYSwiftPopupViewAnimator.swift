//
//  TFYSwiftPopupViewAnimator.swift
//  TFYSwiftPanModel
//
//  弹窗动画器协议，由 OC TFYPopupViewAnimator 迁移。
//

import UIKit

/// 弹窗动画器协议
public protocol TFYSwiftPopupViewAnimator: AnyObject {
    /// 初始化配置：popupView、contentView、backgroundView
    func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView)
    /// 横竖屏切换时刷新布局
    func refreshLayout(popupView: TFYSwiftPopupView, contentView: UIView)
    /// 展示动画
    func display(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void)
    /// 消失动画
    func dismiss(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void)
}
