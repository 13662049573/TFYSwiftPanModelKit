//
//  TFYSwiftUIViewControllerPanModalPresenter.swift
//  TFYSwiftPanModel
//
//  UIViewController 的 PanModal present 扩展，由 OC UIViewController+PanModalPresenter 迁移。
//

import UIKit
import ObjectiveC

private nonisolated(unsafe) var panModalPresentationDelegateKey: UInt8 = 0

extension UIViewController: TFYSwiftPanModalPresenterProtocol {

    public var isPanModalPresented: Bool {
        transitioningDelegate is TFYSwiftPanModalPresentationDelegate
    }

    public var panPanModalPresentationDelegate: TFYSwiftPanModalPresentationDelegate! {
        get {
            objc_getAssociatedObject(self, &panModalPresentationDelegateKey) as? TFYSwiftPanModalPresentationDelegate
        }
        set {
            objc_setAssociatedObject(self, &panModalPresentationDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, sourceView: UIView?, sourceRect: CGRect) {
        presentPanModal(viewControllerToPresent, sourceView: sourceView, sourceRect: sourceRect, completion: nil)
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, sourceView: UIView?, sourceRect: CGRect, completion: (() -> Void)?) {
        if UIApplication.shared.applicationState != .active {
            DispatchQueue.main.async {
                self.presentPanModal(viewControllerToPresent, sourceView: sourceView, sourceRect: sourceRect, completion: completion)
            }
            return
        }

        let interval = viewControllerToPresent.frequentTapPreventionInterval()
        let prevention = TFYSwiftPanModalFrequentTapPrevention.prevention(withInterval: interval)
        prevention.enabled = viewControllerToPresent.shouldPreventFrequentTapping()
        if !prevention.canExecute() {
            if viewControllerToPresent.shouldShowFrequentTapPreventionHint() {
                let hint = viewControllerToPresent.frequentTapPreventionHintText() ?? "请稍后再试"
                let alert = UIAlertController(title: nil, message: hint, preferredStyle: .alert)
                present(alert, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak alert] in
                    alert?.dismiss(animated: true)
                }
            }
            viewControllerToPresent.panModalFrequentTapPreventionStateChanged(isPrevented: true, remainingTime: prevention.currentRemainingTime)
            return
        }
        prevention.triggerPrevention()

        let delegate = TFYSwiftPanModalPresentationDelegate()
        viewControllerToPresent.panPanModalPresentationDelegate = delegate

        if UIDevice.current.userInterfaceIdiom == .pad, let src = sourceView, sourceRect != .zero {
            viewControllerToPresent.modalPresentationStyle = .popover
            viewControllerToPresent.popoverPresentationController?.sourceRect = sourceRect
            viewControllerToPresent.popoverPresentationController?.sourceView = src
            viewControllerToPresent.popoverPresentationController?.delegate = delegate
        } else {
            viewControllerToPresent.modalPresentationStyle = .custom
            viewControllerToPresent.modalPresentationCapturesStatusBarAppearance = true
            viewControllerToPresent.transitioningDelegate = delegate
        }

        DispatchQueue.main.async {
            self.present(viewControllerToPresent, animated: true, completion: completion)
        }
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable) {
        presentPanModal(viewControllerToPresent, completion: nil)
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, completion: (() -> Void)?) {
        presentPanModal(viewControllerToPresent, sourceView: nil, sourceRect: .zero, completion: completion)
    }
}
