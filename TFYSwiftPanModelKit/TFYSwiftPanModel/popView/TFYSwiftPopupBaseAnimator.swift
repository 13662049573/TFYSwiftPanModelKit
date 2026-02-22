//
//  TFYSwiftPopupBaseAnimator.swift
//  TFYSwiftPanModel
//
//  弹窗基础动画器，由 OC TFYPopupBaseAnimator 迁移。
//

import UIKit

/// 动画完成回调
public typealias TFYPopupAnimationCompletionBlock = () -> Void

/// 弹窗基础动画器
public class TFYSwiftPopupBaseAnimator: NSObject, TFYSwiftPopupViewAnimator {
    public var layout: TFYSwiftPopupAnimatorLayout

    public var displayDuration: TimeInterval = 0.25
    public var displayAnimationOptions: UIView.AnimationOptions = .curveEaseInOut
    public var displaySpringDampingRatio: CGFloat = 0
    public var hasDisplaySpringDampingRatio: Bool = false
    public var displaySpringVelocity: CGFloat = 0
    public var hasDisplaySpringVelocity: Bool = false
    public var displayAnimationBlock: TFYPopupAnimationCompletionBlock?

    public var dismissDuration: TimeInterval = 0.25
    public var dismissAnimationOptions: UIView.AnimationOptions = .curveEaseInOut
    public var dismissSpringDampingRatio: CGFloat = 0
    public var hasDismissSpringDampingRatio: Bool = false
    public var dismissSpringVelocity: CGFloat = 0
    public var hasDismissSpringVelocity: Bool = false
    public var dismissAnimationBlock: TFYPopupAnimationCompletionBlock?

    private var layoutConstraints: [NSLayoutConstraint] = []

    public override init() {
        layout = TFYSwiftPopupAnimatorLayout.center(TFYSwiftPopupAnimatorLayoutCenter.default())
        super.init()
    }

    public init(layout: TFYSwiftPopupAnimatorLayout) {
        self.layout = layout
        super.init()
    }

    // MARK: - TFYSwiftPopupViewAnimator

    public func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        setupLayout(popupView: popupView, contentView: contentView)
    }

    public func refreshLayout(popupView: TFYSwiftPopupView, contentView: UIView) {
        if layout.type == .frame {
            contentView.frame = layout.frameLayout
        }
    }

    public func display(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void) {
        if animated {
            if hasDisplaySpringDampingRatio, hasDisplaySpringVelocity {
                UIView.animate(withDuration: displayDuration, delay: 0, usingSpringWithDamping: displaySpringDampingRatio, initialSpringVelocity: displaySpringVelocity, options: displayAnimationOptions) {
                    self.displayAnimationBlock?()
                } completion: { _ in completion() }
            } else {
                UIView.animate(withDuration: displayDuration, delay: 0, options: displayAnimationOptions) {
                    self.displayAnimationBlock?()
                } completion: { _ in completion() }
            }
        } else {
            displayAnimationBlock?()
            completion()
        }
    }

    public func dismiss(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void) {
        if animated {
            if hasDismissSpringDampingRatio, hasDismissSpringVelocity {
                UIView.animate(withDuration: dismissDuration, delay: 0, usingSpringWithDamping: dismissSpringDampingRatio, initialSpringVelocity: dismissSpringVelocity, options: dismissAnimationOptions) {
                    self.dismissAnimationBlock?()
                } completion: { _ in completion() }
            } else {
                UIView.animate(withDuration: dismissDuration, delay: 0, options: dismissAnimationOptions) {
                    self.dismissAnimationBlock?()
                } completion: { _ in completion() }
            }
        } else {
            dismissAnimationBlock?()
            completion()
        }
    }

    // MARK: - Layout Setup

    /// contentView 相对于它的 superview 进行布局（superview 通常是 window/container）
    public func setupLayout(popupView: TFYSwiftPopupView, contentView: UIView) {
        NSLayoutConstraint.deactivate(layoutConstraints)
        layoutConstraints.removeAll()

        guard let superView = contentView.superview else { return }

        if layout.type == .frame {
            contentView.translatesAutoresizingMaskIntoConstraints = true
            contentView.frame = layout.frameLayout
            return
        }

        contentView.translatesAutoresizingMaskIntoConstraints = false

        switch layout.type {
        case .center:
            if let center = layout.centerLayout {
                setupCenterLayout(superView: superView, contentView: contentView, center: center)
            }
        case .top:
            if let top = layout.topLayout {
                setupTopLayout(superView: superView, contentView: contentView, top: top)
            }
        case .bottom:
            if let bottom = layout.bottomLayout {
                setupBottomLayout(superView: superView, contentView: contentView, bottom: bottom)
            }
        case .leading:
            if let leading = layout.leadingLayout {
                setupLeadingLayout(superView: superView, contentView: contentView, leading: leading)
            }
        case .trailing:
            if let trailing = layout.trailingLayout {
                setupTrailingLayout(superView: superView, contentView: contentView, trailing: trailing)
            }
        case .frame:
            break
        }

        NSLayoutConstraint.activate(layoutConstraints)
        superView.layoutIfNeeded()
    }

    private func setupCenterLayout(superView: UIView, contentView: UIView, center: TFYSwiftPopupAnimatorLayoutCenter) {
        layoutConstraints.append(contentView.centerXAnchor.constraint(equalTo: superView.centerXAnchor, constant: center.offsetX))
        layoutConstraints.append(contentView.centerYAnchor.constraint(equalTo: superView.centerYAnchor, constant: center.offsetY))
        if center.hasWidth { layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: center.width)) }
        if center.hasHeight { layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: center.height)) }
    }

    private func setupTopLayout(superView: UIView, contentView: UIView, top: TFYSwiftPopupAnimatorLayoutTop) {
        layoutConstraints.append(contentView.topAnchor.constraint(equalTo: superView.safeAreaLayoutGuide.topAnchor, constant: top.topMargin))
        layoutConstraints.append(contentView.centerXAnchor.constraint(equalTo: superView.centerXAnchor, constant: top.offsetX))
        if top.hasWidth {
            layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: top.width))
        } else {
            layoutConstraints.append(contentView.leadingAnchor.constraint(equalTo: superView.leadingAnchor))
            layoutConstraints.append(contentView.trailingAnchor.constraint(equalTo: superView.trailingAnchor))
        }
        if top.hasHeight { layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: top.height)) }
    }

    private func setupBottomLayout(superView: UIView, contentView: UIView, bottom: TFYSwiftPopupAnimatorLayoutBottom) {
        layoutConstraints.append(contentView.bottomAnchor.constraint(equalTo: superView.bottomAnchor, constant: -bottom.bottomMargin))
        layoutConstraints.append(contentView.centerXAnchor.constraint(equalTo: superView.centerXAnchor, constant: bottom.offsetX))
        if bottom.hasWidth {
            layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: bottom.width))
        } else {
            layoutConstraints.append(contentView.leadingAnchor.constraint(equalTo: superView.leadingAnchor))
            layoutConstraints.append(contentView.trailingAnchor.constraint(equalTo: superView.trailingAnchor))
        }
        if bottom.hasHeight { layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: bottom.height)) }
    }

    private func setupLeadingLayout(superView: UIView, contentView: UIView, leading: TFYSwiftPopupAnimatorLayoutLeading) {
        layoutConstraints.append(contentView.leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: leading.leadingMargin))
        layoutConstraints.append(contentView.centerYAnchor.constraint(equalTo: superView.centerYAnchor, constant: leading.offsetY))
        if leading.hasWidth { layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: leading.width)) }
        if !leading.hasHeight {
            layoutConstraints.append(contentView.topAnchor.constraint(equalTo: superView.topAnchor))
            layoutConstraints.append(contentView.bottomAnchor.constraint(equalTo: superView.bottomAnchor))
        } else {
            layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: leading.height))
        }
    }

    private func setupTrailingLayout(superView: UIView, contentView: UIView, trailing: TFYSwiftPopupAnimatorLayoutTrailing) {
        layoutConstraints.append(contentView.trailingAnchor.constraint(equalTo: superView.trailingAnchor, constant: -trailing.trailingMargin))
        layoutConstraints.append(contentView.centerYAnchor.constraint(equalTo: superView.centerYAnchor, constant: trailing.offsetY))
        if trailing.hasWidth { layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: trailing.width)) }
        if !trailing.hasHeight {
            layoutConstraints.append(contentView.topAnchor.constraint(equalTo: superView.topAnchor))
            layoutConstraints.append(contentView.bottomAnchor.constraint(equalTo: superView.bottomAnchor))
        } else {
            layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: trailing.height))
        }
    }
}
