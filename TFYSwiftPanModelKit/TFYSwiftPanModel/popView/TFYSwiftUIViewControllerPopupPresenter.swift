//
//  TFYSwiftUIViewControllerPopupPresenter.swift
//  TFYSwiftPanModel
//
//  UIViewController.presentPopup — 用 PopupView 体系弹出任意控制器。
//

import UIKit
import ObjectiveC

// MARK: - Storage

private final class TFYSwiftWeakHostingBox: NSObject {
    weak var hosting: TFYSwiftPopupHostingView?
    init(_ hosting: TFYSwiftPopupHostingView?) {
        self.hosting = hosting
    }
}

enum TFYSwiftPopupPresenterStorage {
    private static var hostingKey: UInt8 = 0
    private static var activeHostsKey: UInt8 = 0

    static func setHosting(_ hosting: TFYSwiftPopupHostingView?, for content: UIViewController?) {
        guard let content else { return }
        objc_setAssociatedObject(
            content,
            &hostingKey,
            TFYSwiftWeakHostingBox(hosting),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    static func hosting(for content: UIViewController?) -> TFYSwiftPopupHostingView? {
        guard let content else { return nil }
        return (objc_getAssociatedObject(content, &hostingKey) as? TFYSwiftWeakHostingBox)?.hosting
    }

    static func clear(for content: UIViewController?) {
        setHosting(nil, for: content)
    }

    static func append(_ hosting: TFYSwiftPopupHostingView, to presenter: UIViewController) {
        var hosts = activeHosts(for: presenter)
        hosts.append(hosting)
        objc_setAssociatedObject(presenter, &activeHostsKey, hosts, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static func remove(_ hosting: TFYSwiftPopupHostingView?, from presenter: UIViewController) {
        guard let hosting else { return }
        var hosts = activeHosts(for: presenter)
        hosts.removeAll { $0 === hosting }
        objc_setAssociatedObject(presenter, &activeHostsKey, hosts, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    static func activeHosts(for presenter: UIViewController) -> [TFYSwiftPopupHostingView] {
        (objc_getAssociatedObject(presenter, &activeHostsKey) as? [TFYSwiftPopupHostingView]) ?? []
    }
}

// MARK: - Presenter Protocol

/// PopupView 控制器弹出协议
public protocol TFYSwiftPopupPresenterProtocol: AnyObject {
    /// 当前是否有通过 presentPopup 弹出的弹窗
    var hasPresentedPopup: Bool { get }

    /// 用 PopupView 体系弹出任意 UIViewController
    func presentPopup(
        _ viewController: UIViewController,
        animator: TFYSwiftPopupViewAnimator?,
        configuration: TFYSwiftPopupViewConfiguration?,
        layout: TFYSwiftPopupAnimatorLayout?,
        in container: UIView?,
        animated: Bool,
        completion: (() -> Void)?
    )

    /// 关闭最近一次通过 presentPopup 弹出的弹窗
    func dismissPresentedPopup(animated: Bool, completion: (() -> Void)?)
}

// MARK: - UIViewController

extension UIViewController: TFYSwiftPopupPresenterProtocol {

    public var hasPresentedPopup: Bool {
        !TFYSwiftPopupPresenterStorage.activeHosts(for: self).isEmpty
    }

    /// 当前 VC 是否正作为 PopupView 内容展示
    public var isPresentedAsPopup: Bool {
        TFYSwiftPopupPresenterStorage.hosting(for: self) != nil
    }

    /// 所属 Popup 宿主视图（仅内容 VC 有值）
    public var popupHostingView: TFYSwiftPopupHostingView? {
        TFYSwiftPopupPresenterStorage.hosting(for: self)
    }

    public func presentPopup(
        _ viewController: UIViewController,
        animator: TFYSwiftPopupViewAnimator?,
        configuration: TFYSwiftPopupViewConfiguration?,
        layout: TFYSwiftPopupAnimatorLayout?,
        in container: UIView?,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        let work = { [weak self] in
            guard let self else {
                completion?()
                return
            }
            self.performPresentPopup(
                viewController,
                animator: animator,
                configuration: configuration,
                layout: layout,
                in: container,
                animated: animated,
                completion: completion
            )
        }

        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func performPresentPopup(
        _ viewController: UIViewController,
        animator: TFYSwiftPopupViewAnimator?,
        configuration: TFYSwiftPopupViewConfiguration?,
        layout: TFYSwiftPopupAnimatorLayout?,
        in container: UIView?,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        // 默认挂到 window，避免加在 UITableView 上等会被裁剪/遮挡的容器
        let targetContainer = container
            ?? view.window
            ?? TFYSwiftWindowHelper.activeWindow
            ?? view

        let preferredSize = viewController.popupPreferredContentSize()
        let config: TFYSwiftPopupViewConfiguration = {
            if let configuration {
                return configuration
            }
            let copied = (viewController.popupConfiguration().copy() as? TFYSwiftPopupViewConfiguration)
                ?? TFYSwiftPopupViewConfiguration()
            // 未显式传 configuration 时默认立即展示，避免被优先级队列静默卡住
            copied.enablePriorityManagement = false
            return copied
        }()

        let resolvedLayout = layout
            ?? viewController.popupPreferredLayout()
            ?? defaultCenterLayout(for: preferredSize)
        let resolvedAnimator = resolveAnimator(
            preferred: animator ?? viewController.popupPreferredAnimator(),
            layout: resolvedLayout
        )

        let hosting = TFYSwiftPopupHostingView(contentViewController: viewController)
        hosting.install(in: self, preferredSize: preferredSize)
        if config.cornerRadius > 0 {
            hosting.layer.cornerRadius = config.cornerRadius
            hosting.layer.masksToBounds = true
        }

        TFYSwiftPopupPresenterStorage.setHosting(hosting, for: viewController)
        TFYSwiftPopupPresenterStorage.append(hosting, to: self)

        hosting.show(
            in: targetContainer,
            animator: resolvedAnimator,
            configuration: config,
            animated: animated
        ) { [weak hosting, weak viewController, weak self] in
            guard let hosting else {
                TFYSwiftPopupPresenterStorage.clear(for: viewController)
                completion?()
                return
            }
            if !hosting.isShowing {
                TFYSwiftPopupPriorityManager.shared.remove(popup: hosting)
                TFYSwiftPopupPresenterStorage.clear(for: viewController)
                if let parent = hosting.presentingParent ?? self {
                    TFYSwiftPopupPresenterStorage.remove(hosting, from: parent)
                }
                hosting.uninstallContent()
            }
            completion?()
        }
    }

    /// 便捷重载：使用默认 Spring 居中动画
    public func presentPopup(
        _ viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        presentPopup(
            viewController,
            animator: nil,
            configuration: nil,
            layout: nil,
            in: nil,
            animated: animated,
            completion: completion
        )
    }

    /// 便捷重载：指定动画器
    public func presentPopup(
        _ viewController: UIViewController,
        animator: TFYSwiftPopupViewAnimator,
        configuration: TFYSwiftPopupViewConfiguration? = nil,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        presentPopup(
            viewController,
            animator: animator,
            configuration: configuration,
            layout: nil,
            in: nil,
            animated: animated,
            completion: completion
        )
    }

    public func dismissPresentedPopup(animated: Bool = true, completion: (() -> Void)? = nil) {
        let hosts = TFYSwiftPopupPresenterStorage.activeHosts(for: self)
        guard let hosting = hosts.last else {
            completion?()
            return
        }
        hosting.dismissAnimated(animated, completion: completion)
    }

    /// 内容 VC 关闭自身所在 Popup；若非 Popup 内容则尝试关闭自己弹出的 Popup
    public func popupDismissAnimated(_ animated: Bool = true, completion: (() -> Void)? = nil) {
        if let hosting = resolvePopupHostingView() {
            // 关闭按钮等程序化关闭：force=true，不受 shouldDismiss 拦截
            hosting.dismissAnimated(animated, force: true, completion: completion)
            return
        }
        dismissPresentedPopup(animated: animated, completion: completion)
    }

    /// 查找当前 VC 所属的 Popup 宿主
    public func resolvePopupHostingView() -> TFYSwiftPopupHostingView? {
        if let hosting = TFYSwiftPopupPresenterStorage.hosting(for: self) {
            return hosting
        }
        loadViewIfNeeded()
        var node: UIView? = view.superview
        while let current = node {
            if let hosting = current as? TFYSwiftPopupHostingView {
                return hosting
            }
            node = current.superview
        }
        return nil
    }

    // MARK: - Private

    private func defaultCenterLayout(for size: CGSize) -> TFYSwiftPopupAnimatorLayout {
        let width = size.width > 0 ? size.width : 300
        let height = size.height > 0 ? size.height : 220
        return .center(TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: width, height: height))
    }

    private func resolveAnimator(
        preferred: TFYSwiftPopupViewAnimator?,
        layout: TFYSwiftPopupAnimatorLayout
    ) -> TFYSwiftPopupViewAnimator {
        if let preferred {
            if let base = preferred as? TFYSwiftPopupBaseAnimator {
                base.layout = layout
            }
            return preferred
        }
        let spring = TFYSwiftPopupSpringAnimator()
        spring.layout = layout
        return spring
    }
}
