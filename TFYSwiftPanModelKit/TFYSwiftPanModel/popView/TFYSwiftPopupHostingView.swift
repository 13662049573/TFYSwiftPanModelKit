//
//  TFYSwiftPopupHostingView.swift
//  TFYSwiftPanModel
//
//  将 UIViewController 内容嵌入 PopupView。
//  弹窗默认挂在 window 上，不能对 presenting VC 使用 addChild（会触发 UIKit 层级断言）。
//  因此必须由宿主强引用 content VC，否则按钮回调里的 weak self 会变成 nil。
//

import UIKit

/// 承载任意 UIViewController 内容的 PopupView 宿主
open class TFYSwiftPopupHostingView: TFYSwiftPopupView {

    /// 强引用内容控制器（未走 addChild 时必须由宿主持有）
    public private(set) var contentViewController: UIViewController?
    public private(set) weak var presentingParent: UIViewController?

    private var sizeConstraints: [NSLayoutConstraint] = []
    private let bridgeDelegate = TFYSwiftPopupHostingBridge()
    private var hasForwardedAppearance = false

    public init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        clipsToBounds = true
        isUserInteractionEnabled = true
        bridgeDelegate.hostingView = self
        delegate = bridgeDelegate
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 将 content VC 的 view 嵌入宿主（不建立 child VC 关系，避免 window 层级断言）
    public func install(in parent: UIViewController, preferredSize: CGSize) {
        guard let content = contentViewController else { return }
        presentingParent = parent

        if content.parent != nil {
            content.willMove(toParent: nil)
            content.removeFromParent()
        }

        content.loadViewIfNeeded()
        content.view.isUserInteractionEnabled = true
        if content.view.superview !== self {
            addSubview(content.view)
        }
        content.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.deactivate(sizeConstraints)
        sizeConstraints.removeAll()

        var constraints: [NSLayoutConstraint] = [
            content.view.topAnchor.constraint(equalTo: topAnchor),
            content.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]

        if preferredSize.width > 0 {
            let w = widthAnchor.constraint(equalToConstant: preferredSize.width)
            w.priority = .required
            constraints.append(w)
            sizeConstraints.append(w)
        }
        if preferredSize.height > 0 {
            let h = heightAnchor.constraint(equalToConstant: preferredSize.height)
            h.priority = .required
            constraints.append(h)
            sizeConstraints.append(h)
        }

        NSLayoutConstraint.activate(constraints)
    }

    /// 移除内容 view 并释放强引用
    public func uninstallContent() {
        guard let content = contentViewController else { return }
        if hasForwardedAppearance {
            content.beginAppearanceTransition(false, animated: false)
            content.endAppearanceTransition()
            hasForwardedAppearance = false
        }
        if content.parent != nil {
            content.willMove(toParent: nil)
            content.removeFromParent()
        }
        content.view.removeFromSuperview()
        contentViewController = nil
    }

    open override func dismissAnimated(_ animated: Bool, force: Bool = false, completion: (() -> Void)? = nil) {
        super.dismissAnimated(animated, force: force) { [weak self] in
            self?.uninstallContent()
            completion?()
        }
    }

    fileprivate func markAppearanceForwarded(_ forwarded: Bool) {
        hasForwardedAppearance = forwarded
    }

    fileprivate var isAppearanceForwarded: Bool { hasForwardedAppearance }
}

// MARK: - Bridge Delegate

private final class TFYSwiftPopupHostingBridge: NSObject, TFYSwiftPopupViewDelegate {
    weak var hostingView: TFYSwiftPopupHostingView?

    private var contentViewController: UIViewController? {
        hostingView?.contentViewController
    }

    func popupViewWillAppear(_ popupView: TFYSwiftPopupView) {
        guard let content = contentViewController else { return }
        if hostingView?.isAppearanceForwarded != true {
            content.beginAppearanceTransition(true, animated: true)
            hostingView?.markAppearanceForwarded(true)
        }
        content.popupWillAppear()
    }

    func popupViewDidAppear(_ popupView: TFYSwiftPopupView) {
        guard let content = contentViewController else { return }
        if hostingView?.isAppearanceForwarded == true {
            content.endAppearanceTransition()
        }
        content.popupDidAppear()
    }

    func popupViewWillDisappear(_ popupView: TFYSwiftPopupView) {
        guard let content = contentViewController else { return }
        if hostingView?.isAppearanceForwarded == true {
            content.beginAppearanceTransition(false, animated: true)
        }
        content.popupWillDisappear()
    }

    func popupViewDidDisappear(_ popupView: TFYSwiftPopupView) {
        let content = contentViewController
        if let content, hostingView?.isAppearanceForwarded == true {
            content.endAppearanceTransition()
            hostingView?.markAppearanceForwarded(false)
        }
        content?.popupDidDisappear()
        cleanupStorage(for: content)
    }

    func popupViewShouldDismiss(_ popupView: TFYSwiftPopupView) -> Bool {
        contentViewController?.popupShouldDismiss() ?? true
    }

    private func cleanupStorage(for content: UIViewController?) {
        TFYSwiftPopupPresenterStorage.clear(for: content)
        if let parent = hostingView?.presentingParent {
            TFYSwiftPopupPresenterStorage.remove(hostingView, from: parent)
        }
    }
}
