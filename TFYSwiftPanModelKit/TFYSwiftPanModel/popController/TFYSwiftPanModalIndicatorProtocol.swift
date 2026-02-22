//
//  TFYSwiftPanModalIndicatorProtocol.swift
//  TFYSwiftPanModel
//
//  拖拽指示器协议，由 OC TFYPanModalIndicatorProtocol 迁移。
//

import UIKit

/// 拖拽指示器状态
public enum TFYIndicatorState: UInt {
    case normal = 0
    case pullDown
}

/// 指示器相关常量
public enum PanModalIndicatorConstants {
    public static let yOffset: CGFloat = 5
}

@available(*, deprecated, renamed: "PanModalIndicatorConstants.yOffset")
public let kIndicatorYOffset: CGFloat = PanModalIndicatorConstants.yOffset

/// 拖拽指示器协议，支持自定义 UI 和状态切换
public protocol TFYSwiftPanModalIndicatorProtocol: AnyObject {
    /// 状态变更回调
    func didChange(to state: TFYIndicatorState)
    /// 指示器尺寸
    func indicatorSize() -> CGSize
    /// 添加到父视图时的布局回调
    func setupSubviews()
}
