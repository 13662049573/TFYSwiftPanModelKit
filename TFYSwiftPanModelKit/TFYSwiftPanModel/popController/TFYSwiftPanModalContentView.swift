//
//  TFYSwiftPanModalContentView.swift
//  TFYSwiftPanModel
//
//  PanModal 内容视图（可独立 present/dismiss），由 OC TFYPanModalContentView 迁移。
//

import UIKit

/// PanModal 弹窗内容视图，支持独立 present/dismiss，遵循 Presentable 与布局协议
public final class TFYSwiftPanModalContentView: UIView, TFYSwiftPanModalPresentable, TFYSwiftPanModalPanGestureDelegate, TFYSwiftPanModalPresentationUpdateProtocol, TFYSwiftPanModalPresentableLayoutProtocol {

    private weak var _containerView: TFYSwiftPanModalContainerView?
    /// 从 superview 链查找或直接引用
    var containerView: TFYSwiftPanModalContainerView? {
        if let c = _containerView { return c }
        var v: UIView? = superview
        while let vv = v {
            if let c = vv as? TFYSwiftPanModalContainerView { return c }
            v = vv.superview
        }
        return nil
    }

    public var topLayoutOffset: CGFloat { 0 }
    public var bottomLayoutOffset: CGFloat {
        if #available(iOS 15.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                guard let ws = scene as? UIWindowScene, ws.activationState == .foregroundActive,
                      let w = ws.windows.first else { continue }
                return w.safeAreaInsets.bottom
            }
        }
        return 0
    }

    public var shortFormYPos: CGFloat {
        let shortY = topMarginFromPanModalHeight(shortFormHeight()) + topOffset()
        return max(shortY, longFormYPos)
    }

    public var mediumFormYPos: CGFloat {
        let mediumY = topMarginFromPanModalHeight(mediumFormHeight()) + topOffset()
        return max(mediumY, longFormYPos)
    }

    public var longFormYPos: CGFloat {
        let h1 = topMarginFromPanModalHeight(longFormHeight())
        let h2 = topMarginFromPanModalHeight(PanModalHeight(type: .max, height: 0))
        return max(h1, h2) + topOffset()
    }

    public var bottomYPos: CGFloat {
        if let cv = containerView { return cv.bounds.height - topOffset() }
        return bounds.height
    }

    public func topMarginFromPanModalHeight(_ panModalHeight: PanModalHeight) -> CGFloat {
        switch panModalHeight.type {
        case .max: return 0
        case .topInset: return panModalHeight.height
        case .content: return bottomYPos - (panModalHeight.height + bottomLayoutOffset)
        case .contentIgnoringSafeArea: return bottomYPos - panModalHeight.height
        case .intrinsic:
            layoutIfNeeded()
            let w = containerView?.bounds.width ?? TFYSwiftWindowHelper.screenWidth
            let targetSize = CGSize(width: w, height: UIView.layoutFittingCompressedSize.height)
            let height = systemLayoutSizeFitting(targetSize).height
            return bottomYPos - (height + bottomLayoutOffset)
        }
    }

    public func present(in view: UIView?) {
        var targetView = view
        if targetView == nil { targetView = findKeyWindow() }
        if let old = containerView { old.removeFromSuperview(); _containerView = nil }
        guard let v = targetView else { return }
        let container = TFYSwiftPanModalContainerView(presentingView: v, contentView: self)
        _containerView = container
        container.show()
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let cv = containerView else { completion?(); return }
        cv.dismiss(animated: animated, completion: { [weak self] in
            completion?()
            self?._containerView = nil
        })
    }

    // MARK: - TFYSwiftPanModalPresentationUpdateProtocol（未 present 时为 nil）
    public var panDimmedView: TFYSwiftDimmedView? { containerView?.backgroundView }
    public var panRootContainerView: UIView? { containerView }
    public var panContentView: UIView? { containerView?.panContainerView }
    public var panPresentationState: PresentationState { containerView?.currentPresentationState ?? .short }

    public func panModalTransition(to state: PresentationState) { containerView?.transition(to: state, animated: true) }
    public func panModalTransition(to state: PresentationState, animated: Bool) { containerView?.transition(to: state, animated: animated) }
    public func panModalSetContentOffset(_ offset: CGPoint) { containerView?.setScrollableContentOffset(offset, animated: true) }
    public func panModalSetContentOffset(_ offset: CGPoint, animated: Bool) { containerView?.setScrollableContentOffset(offset, animated: animated) }
    public func panModalSetNeedsLayoutUpdate() { containerView?.setNeedsLayoutUpdate() }
    public func panModalUpdateUserHitBehavior() { containerView?.updateUserHitBehavior() }
    public func panModalDismissAnimated(animated: Bool, completion: (() -> Void)?) { dismiss(animated: animated, completion: completion) }

    // MARK: - TFYSwiftPanModalPresentable 默认实现
    public func panScrollable() -> UIScrollView? { nil }
    public func topOffset() -> CGFloat { topLayoutOffset + 21 }
    public func shortFormHeight() -> PanModalHeight { longFormHeight() }
    public func mediumFormHeight() -> PanModalHeight { longFormHeight() }
    public func longFormHeight() -> PanModalHeight {
        if let scroll = panScrollable() {
            scroll.layoutIfNeeded()
            let h = max(scroll.contentSize.height, scroll.bounds.height)
            return PanModalHeight(type: .content, height: h)
        }
        return PanModalHeight(type: .max, height: 0)
    }
    public func originPresentationState() -> PresentationState { .short }
    public func backgroundConfig() -> TFYSwiftBackgroundConfig { TFYSwiftBackgroundConfig.config(behavior: .default) }
    public func contentShadow() -> TFYSwiftPanModalShadow { .none }

    private func findKeyWindow() -> UIView? {
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for w in ws.windows where w.isKeyWindow { return w }
        }
        return nil
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        _containerView?.removeFromSuperview()
    }
}
