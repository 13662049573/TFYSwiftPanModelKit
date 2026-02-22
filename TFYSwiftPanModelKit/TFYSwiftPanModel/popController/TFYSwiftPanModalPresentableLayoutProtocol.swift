//
//  TFYSwiftPanModalPresentableLayoutProtocol.swift
//  TFYSwiftPanModel
//
//  布局协议与 UIViewController+LayoutHelper，由 OC UIViewController+LayoutHelper 迁移。
//

import UIKit

/// 弹窗布局协议，提供 short/medium/long 的 Y 位置等
public protocol TFYSwiftPanModalPresentableLayoutProtocol: AnyObject {
    var topLayoutOffset: CGFloat { get }
    var bottomLayoutOffset: CGFloat { get }
    var shortFormYPos: CGFloat { get }
    var mediumFormYPos: CGFloat { get }
    var longFormYPos: CGFloat { get }
    var bottomYPos: CGFloat { get }
}

extension UIViewController: TFYSwiftPanModalPresentableLayoutProtocol {

    public var panPresentedVC: TFYSwiftPanModalPresentationController? {
        if presentingViewController != nil {
            return panGetPanModalPresentationController()
        }
        return nil
    }

    public var topLayoutOffset: CGFloat {
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene, ws.activationState == .foregroundActive,
                  let window = ws.windows.first else { continue }
            return window.safeAreaInsets.top
        }
        return 0
    }

    public var bottomLayoutOffset: CGFloat {
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene, ws.activationState == .foregroundActive,
                  let window = ws.windows.first else { continue }
            return window.safeAreaInsets.bottom
        }
        return 0
    }

    public var shortFormYPos: CGFloat {
        if UIAccessibility.isVoiceOverRunning { return longFormYPos }
        guard view != nil else { return 0 }
        let shortH = shortFormHeight()
        let top = topOffset()
        let shortY = topMarginFromPanModalHeight(shortH) + top
        return max(shortY, longFormYPos)
    }

    public var mediumFormYPos: CGFloat {
        if UIAccessibility.isVoiceOverRunning { return longFormYPos }
        guard view != nil else { return 0 }
        let mediumH = mediumFormHeight()
        let top = topOffset()
        let mediumY = topMarginFromPanModalHeight(mediumH) + top
        return max(mediumY, longFormYPos)
    }

    public var longFormYPos: CGFloat {
        guard view != nil else { return 0 }
        let longH = longFormHeight()
        let top = topOffset()
        let h1 = topMarginFromPanModalHeight(longH)
        let h2 = topMarginFromPanModalHeight(PanModalHeight(type: .max, height: 0))
        return max(h1, h2) + top
    }

    public var bottomYPos: CGFloat {
        if let vc = panPresentedVC, let container = vc.containerView {
            return container.bounds.height - topOffset()
        }
        guard let view = view else { return 0 }
        return view.bounds.height
    }

    func panGetPanModalPresentationController() -> TFYSwiftPanModalPresentationController? {
        let ancestorsVC: UIViewController = {
            if let s = splitViewController { return s }
            if let n = navigationController { return n }
            if let t = tabBarController { return t }
            return self
        }()
        if let pc = ancestorsVC.presentationController as? TFYSwiftPanModalPresentationController {
            return pc
        }
        return nil
    }

    func topMarginFromPanModalHeight(_ panModalHeight: PanModalHeight) -> CGFloat {
        guard view != nil else { return 0 }
        switch panModalHeight.type {
        case .max: return 0
        case .topInset: return panModalHeight.height
        case .content: return bottomYPos - (panModalHeight.height + bottomLayoutOffset)
        case .contentIgnoringSafeArea: return bottomYPos - panModalHeight.height
        case .intrinsic:
            view?.layoutIfNeeded()
            let w = (panPresentedVC?.containerView?.bounds.width ?? TFYSwiftWindowHelper.screenWidth)
            let targetSize = CGSize(width: w, height: UIView.layoutFittingCompressedSize.height)
            let height = view?.systemLayoutSizeFitting(targetSize).height ?? 0
            return bottomYPos - (height + bottomLayoutOffset)
        }
    }
}
