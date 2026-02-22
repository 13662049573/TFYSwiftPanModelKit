//
//  TFYSwiftPanModalPresentationUpdateProtocol.swift
//  TFYSwiftPanModel
//
//  PanModal 展示更新协议，由 OC TFYPanModalPresentationUpdateProtocol 迁移。
//

import UIKit

/// PanModal 弹窗展示更新协议（未 present 时视图属性可为 nil）
public protocol TFYSwiftPanModalPresentationUpdateProtocol: AnyObject {
    var panDimmedView: TFYSwiftDimmedView? { get }
    var panRootContainerView: UIView? { get }
    var panContentView: UIView? { get }
    var panPresentationState: PresentationState { get }

    func panModalTransition(to state: PresentationState)
    func panModalTransition(to state: PresentationState, animated: Bool)
    func panModalSetContentOffset(_ offset: CGPoint)
    func panModalSetContentOffset(_ offset: CGPoint, animated: Bool)
    func panModalSetNeedsLayoutUpdate()
    func panModalUpdateUserHitBehavior()
    func panModalDismissAnimated(animated: Bool, completion: (() -> Void)?)
}
