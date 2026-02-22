//
//  TFYSwiftPanModalPanGestureDelegate.swift
//  TFYSwiftPanModel
//
//  PanModal 手势代理协议，由 OC TFYPanModalPanGestureDelegate 迁移。
//

import UIKit

/// PanModal 弹窗手势代理，支持自定义拖拽、边缘滑动等
public protocol TFYSwiftPanModalPanGestureDelegate: AnyObject {
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    func panGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool
    func panGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool
    func panGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf other: UIGestureRecognizer) -> Bool
}

public extension TFYSwiftPanModalPanGestureDelegate {
    func panGestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool { true }
    func panGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { false }
    func panGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool { false }
    func panGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf other: UIGestureRecognizer) -> Bool { false }
}
