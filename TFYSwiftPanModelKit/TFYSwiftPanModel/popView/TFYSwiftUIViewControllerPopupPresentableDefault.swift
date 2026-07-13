//
//  TFYSwiftUIViewControllerPopupPresentableDefault.swift
//  TFYSwiftPanModel
//
//  UIViewController 的 PopupPresentable 默认实现。
//  需要 override 动画器/布局/配置时，请继承 TFYSwiftPopupContentViewController，
//  或在 presentPopup(..., animator:/configuration:/layout:) 中显式传入。
//

import UIKit

extension UIViewController: TFYSwiftPopupPresentable {

    public func popupPreferredContentSize() -> CGSize {
        if let content = self as? TFYSwiftPopupContentViewController {
            return content.preferredPopupContentSize()
        }
        if preferredContentSize.width > 0, preferredContentSize.height > 0 {
            return preferredContentSize
        }
        return CGSize(width: 300, height: 220)
    }

    public func popupConfiguration() -> TFYSwiftPopupViewConfiguration {
        if let content = self as? TFYSwiftPopupContentViewController {
            return content.preferredPopupConfiguration()
        }
        return TFYSwiftPopupViewConfiguration()
    }

    public func popupPreferredAnimator() -> TFYSwiftPopupViewAnimator? {
        if let content = self as? TFYSwiftPopupContentViewController {
            return content.preferredPopupAnimator()
        }
        return nil
    }

    public func popupPreferredLayout() -> TFYSwiftPopupAnimatorLayout? {
        if let content = self as? TFYSwiftPopupContentViewController {
            return content.preferredPopupLayout()
        }
        return nil
    }

    public func popupShouldDismiss() -> Bool {
        if let content = self as? TFYSwiftPopupContentViewController {
            return content.shouldAllowPopupDismiss()
        }
        return true
    }

    public func popupWillAppear() {
        (self as? TFYSwiftPopupContentViewController)?.popupContentWillAppear()
    }

    public func popupDidAppear() {
        (self as? TFYSwiftPopupContentViewController)?.popupContentDidAppear()
    }

    public func popupWillDisappear() {
        (self as? TFYSwiftPopupContentViewController)?.popupContentWillDisappear()
    }

    public func popupDidDisappear() {
        (self as? TFYSwiftPopupContentViewController)?.popupContentDidDisappear()
    }
}

/// 可 override 的 Popup 内容控制器基类（任意动画弹窗推荐继承此类）
open class TFYSwiftPopupContentViewController: UIViewController {

    open func preferredPopupContentSize() -> CGSize {
        if preferredContentSize.width > 0, preferredContentSize.height > 0 {
            return preferredContentSize
        }
        return CGSize(width: 300, height: 220)
    }

    open func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.cornerRadius = 16
        config.enablePriorityManagement = false
        return config
    }

    open func preferredPopupAnimator() -> TFYSwiftPopupViewAnimator? { nil }

    open func preferredPopupLayout() -> TFYSwiftPopupAnimatorLayout? { nil }

    open func shouldAllowPopupDismiss() -> Bool { true }

    open func popupContentWillAppear() {}
    open func popupContentDidAppear() {}
    open func popupContentWillDisappear() {}
    open func popupContentDidDisappear() {}

    /// 关闭自身所在的 Popup（程序化关闭，一定可关）
    public func dismissPopup(animated: Bool = true, completion: (() -> Void)? = nil) {
        popupDismissAnimated(animated, completion: completion)
    }
}
