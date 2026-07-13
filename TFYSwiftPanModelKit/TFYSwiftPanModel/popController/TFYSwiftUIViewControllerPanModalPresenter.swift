//
//  TFYSwiftUIViewControllerPanModalPresenter.swift
//  TFYSwiftPanModel
//
//  UIViewController 的 PanModal present 扩展，由 OC UIViewController+PanModalPresenter 迁移。
//

import UIKit
import ObjectiveC

private nonisolated(unsafe) var panModalPresentationDelegateKey: UInt8 = 0
private nonisolated(unsafe) var panModalFrequentTapPreventionKey: UInt8 = 0
private nonisolated(unsafe) var panModalPendingPresentationKey: UInt8 = 0

/// Keeps one deferred presentation alive without repeatedly rescheduling while the app is inactive.
private final class TFYSwiftPendingPanModalPresentation: NSObject {
    private var observer: NSObjectProtocol?
    private var action: (() -> Void)?

    init(action: @escaping () -> Void) {
        self.action = action
        super.init()
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.perform()
        }
    }

    func cancel() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        action = nil
    }

    private func perform() {
        let pendingAction = action
        cancel()
        pendingAction?()
    }

    deinit {
        cancel()
    }
}

extension UIViewController: TFYSwiftPanModalPresenterProtocol {

    public var isPanModalPresented: Bool {
        presentingViewController != nil && transitioningDelegate is TFYSwiftPanModalPresentationDelegate
    }

    public var panPanModalPresentationDelegate: TFYSwiftPanModalPresentationDelegate! {
        get {
            objc_getAssociatedObject(self, &panModalPresentationDelegateKey) as? TFYSwiftPanModalPresentationDelegate
        }
        set {
            objc_setAssociatedObject(self, &panModalPresentationDelegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Present 路径持久防连点实例（跨多次 presentPanModal 生效）
    private var panModalPresentFrequentTapPrevention: TFYSwiftPanModalFrequentTapPrevention {
        if let existing = objc_getAssociatedObject(self, &panModalFrequentTapPreventionKey) as? TFYSwiftPanModalFrequentTapPrevention {
            return existing
        }
        let prevention = TFYSwiftPanModalFrequentTapPrevention(preventionInterval: 1)
        objc_setAssociatedObject(self, &panModalFrequentTapPreventionKey, prevention, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return prevention
    }

    private var pendingPanModalPresentation: TFYSwiftPendingPanModalPresentation? {
        get {
            objc_getAssociatedObject(self, &panModalPendingPresentationKey) as? TFYSwiftPendingPanModalPresentation
        }
        set {
            let previous = objc_getAssociatedObject(self, &panModalPendingPresentationKey) as? TFYSwiftPendingPanModalPresentation
            if previous !== newValue {
                previous?.cancel()
            }
            objc_setAssociatedObject(self, &panModalPendingPresentationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, sourceView: UIView?, sourceRect: CGRect) {
        presentPanModal(viewControllerToPresent, sourceView: sourceView, sourceRect: sourceRect, completion: nil)
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, sourceView: UIView?, sourceRect: CGRect, completion: (() -> Void)?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.presentPanModal(
                    viewControllerToPresent,
                    sourceView: sourceView,
                    sourceRect: sourceRect,
                    completion: completion
                )
            }
            return
        }

        if UIApplication.shared.applicationState != .active {
            pendingPanModalPresentation = TFYSwiftPendingPanModalPresentation { [weak self] in
                guard let self else { return }
                self.pendingPanModalPresentation = nil
                self.presentPanModal(
                    viewControllerToPresent,
                    sourceView: sourceView,
                    sourceRect: sourceRect,
                    completion: completion
                )
            }
            return
        }
        pendingPanModalPresentation = nil

        let interval = viewControllerToPresent.frequentTapPreventionInterval()
        let prevention = panModalPresentFrequentTapPrevention
        prevention.preventionInterval = interval
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

        present(viewControllerToPresent, animated: true, completion: completion)
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable) {
        presentPanModal(viewControllerToPresent, completion: nil)
    }

    public func presentPanModal(_ viewControllerToPresent: UIViewController & TFYSwiftPanModalPresentable, completion: (() -> Void)?) {
        presentPanModal(viewControllerToPresent, sourceView: nil, sourceRect: .zero, completion: completion)
    }
}
