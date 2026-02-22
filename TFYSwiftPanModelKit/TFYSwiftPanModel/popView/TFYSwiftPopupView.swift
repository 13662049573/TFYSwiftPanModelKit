//
//  TFYSwiftPopupView.swift
//  TFYSwiftPanModel
//
//  弹窗视图核心类，管理展示/隐藏生命周期。
//

import UIKit

/// 弹窗视图，管理 animator + backgroundView 的展示与隐藏生命周期
open class TFYSwiftPopupView: UIView {

    public weak var delegate: TFYSwiftPopupViewDelegate?
    public var animator: TFYSwiftPopupViewAnimator?
    public private(set) var backgroundView: TFYSwiftPopupBackgroundView?
    public private(set) var isShowing: Bool = false

    private weak var containerView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 在指定容器中展示弹窗
    public func show(in container: UIView, animator: TFYSwiftPopupViewAnimator, backgroundView: TFYSwiftPopupBackgroundView? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        guard !isShowing else { return }

        self.animator = animator
        self.containerView = container

        let bgView = backgroundView ?? {
            let bg = TFYSwiftPopupBackgroundView()
            bg.style = .solidColor
            bg.color = UIColor.black.withAlphaComponent(0.4)
            return bg
        }()
        self.backgroundView = bgView
        bgView.frame = container.bounds
        bgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgView.addTarget(self, action: #selector(backgroundTapped), for: .touchUpInside)

        container.addSubview(bgView)
        container.addSubview(self)

        animator.setup(popupView: self, contentView: self, backgroundView: bgView)

        delegate?.popupViewWillAppear(self)
        isShowing = true

        animator.display(contentView: self, backgroundView: bgView, animated: animated) { [weak self] in
            guard let self else { return }
            self.delegate?.popupViewDidAppear(self)
            completion?()
        }
    }

    /// 关闭弹窗
    open func dismissAnimated(_ animated: Bool, completion: (() -> Void)? = nil) {
        guard isShowing, let animator = animator, let bgView = backgroundView else {
            completion?()
            return
        }

        if delegate?.popupViewShouldDismiss(self) == false { return }

        delegate?.popupViewWillDisappear(self)

        animator.dismiss(contentView: self, backgroundView: bgView, animated: animated) { [weak self] in
            guard let self else { return }
            self.removeFromSuperview()
            bgView.removeFromSuperview()
            self.isShowing = false
            self.animator = nil
            self.backgroundView = nil
            self.delegate?.popupViewDidDisappear(self)
            completion?()
        }
    }

    @objc private func backgroundTapped() {
        delegate?.popupViewDidTapBackground(self)
        dismissAnimated(true)
    }

    deinit {
        backgroundView?.removeFromSuperview()
    }
}
