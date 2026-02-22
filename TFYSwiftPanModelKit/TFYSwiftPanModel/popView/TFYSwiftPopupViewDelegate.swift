//
//  TFYSwiftPopupViewDelegate.swift
//  TFYSwiftPanModel
//
//  弹窗视图代理协议，由 OC TFYPopupViewDelegate 迁移。
//

import UIKit

/// 弹窗视图代理协议
public protocol TFYSwiftPopupViewDelegate: AnyObject {
    func popupViewWillAppear(_ popupView: TFYSwiftPopupView)
    func popupViewDidAppear(_ popupView: TFYSwiftPopupView)
    func popupViewWillDisappear(_ popupView: TFYSwiftPopupView)
    func popupViewDidDisappear(_ popupView: TFYSwiftPopupView)
    func popupViewDidReceiveMemoryWarning(_ popupView: TFYSwiftPopupView)
    func popupViewShouldDismiss(_ popupView: TFYSwiftPopupView) -> Bool
    func popupViewDidTapBackground(_ popupView: TFYSwiftPopupView)
    func popupViewDidSwipeToDismiss(_ popupView: TFYSwiftPopupView)
    func popupViewDidDragToDismiss(_ popupView: TFYSwiftPopupView)
}

public extension TFYSwiftPopupViewDelegate {
    func popupViewWillAppear(_ popupView: TFYSwiftPopupView) {}
    func popupViewDidAppear(_ popupView: TFYSwiftPopupView) {}
    func popupViewWillDisappear(_ popupView: TFYSwiftPopupView) {}
    func popupViewDidDisappear(_ popupView: TFYSwiftPopupView) {}
    func popupViewDidReceiveMemoryWarning(_ popupView: TFYSwiftPopupView) {}
    func popupViewShouldDismiss(_ popupView: TFYSwiftPopupView) -> Bool { true }
    func popupViewDidTapBackground(_ popupView: TFYSwiftPopupView) {}
    func popupViewDidSwipeToDismiss(_ popupView: TFYSwiftPopupView) {}
    func popupViewDidDragToDismiss(_ popupView: TFYSwiftPopupView) {}
}
