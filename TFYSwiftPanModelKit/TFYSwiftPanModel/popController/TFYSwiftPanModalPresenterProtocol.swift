//
//  TFYSwiftPanModalPresenterProtocol.swift
//  TFYSwiftPanModel
//
//  PanModal presenter 协议，由 OC TFYPanModalPresenterProtocol 迁移。
//

import UIKit

/// PanModal 弹窗 presenter 协议
public protocol TFYSwiftPanModalPresenterProtocol: AnyObject {
    var isPanModalPresented: Bool { get }
    var panPanModalPresentationDelegate: TFYSwiftPanModalPresentationDelegate! { get set }

    func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, sourceView: UIView?, sourceRect: CGRect)
    func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, sourceView: UIView?, sourceRect: CGRect, completion: (() -> Void)?)
    func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable)
    func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, completion: (() -> Void)?)
}
