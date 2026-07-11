//
//  TFYSwiftPanModalLayoutHelper.swift
//  TFYSwiftPanModel
//
//  PanModal 共享布局辅助（圆角 mask / 高度边距），供 VC 与 View 路径复用。
//

import UIKit

enum TFYSwiftPanModalLayoutHelper {

    /// 复用或创建顶部圆角 mask，避免每次分配新 CAShapeLayer
    static func applyTopRoundedCorners(to view: UIView, radius: CGFloat, enabled: Bool) {
        guard enabled, radius > 0, view.bounds.width > 0, view.bounds.height > 0 else {
            view.layer.mask = nil
            return
        }
        let path = UIBezierPath(
            roundedRect: view.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        if let mask = view.layer.mask as? CAShapeLayer {
            mask.path = path.cgPath
            mask.frame = view.bounds
        } else {
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            mask.frame = view.bounds
            view.layer.mask = mask
        }
    }

    /// 根据 PanModalHeight 计算距顶部边距
    static func topMargin(
        for panModalHeight: PanModalHeight,
        bottomYPos: CGFloat,
        bottomLayoutOffset: CGFloat,
        intrinsicHeightProvider: (() -> CGFloat)?
    ) -> CGFloat {
        switch panModalHeight.type {
        case .max:
            return 0
        case .topInset:
            return panModalHeight.height
        case .content:
            return bottomYPos - (panModalHeight.height + bottomLayoutOffset)
        case .contentIgnoringSafeArea:
            return bottomYPos - panModalHeight.height
        case .intrinsic:
            let height = intrinsicHeightProvider?() ?? 0
            return bottomYPos - (height + bottomLayoutOffset)
        }
    }

    static func dragIndicatorFrame(containerWidth: CGFloat, indicatorSize: CGSize) -> CGRect {
        CGRect(
            x: (containerWidth - indicatorSize.width) / 2,
            y: -PanModalIndicatorConstants.yOffset - indicatorSize.height,
            width: indicatorSize.width,
            height: indicatorSize.height
        )
    }
}
