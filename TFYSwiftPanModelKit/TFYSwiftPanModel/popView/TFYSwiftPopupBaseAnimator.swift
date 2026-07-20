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
                setupCenterLayout(popupView: popupView, superView: superView, contentView: contentView, center: center)
            }
        case .top:
            if let top = layout.topLayout {
                setupTopLayout(popupView: popupView, superView: superView, contentView: contentView, top: top)
            }
        case .bottom:
            if let bottom = layout.bottomLayout {
                setupBottomLayout(popupView: popupView, superView: superView, contentView: contentView, bottom: bottom)
            }
        case .leading:
            if let leading = layout.leadingLayout {
                setupLeadingLayout(popupView: popupView, superView: superView, contentView: contentView, leading: leading)
            }
        case .trailing:
            if let trailing = layout.trailingLayout {
                setupTrailingLayout(popupView: popupView, superView: superView, contentView: contentView, trailing: trailing)
            }
        case .frame:
            break
        }

        applyContainerDimensions(
            popupView.configuration.containerConfiguration,
            superView: superView,
            contentView: contentView
        )
        NSLayoutConstraint.activate(layoutConstraints)
        superView.layoutIfNeeded()
    }

    private func setupCenterLayout(popupView: TFYSwiftPopupView, superView: UIView, contentView: UIView, center: TFYSwiftPopupAnimatorLayoutCenter) {
        let respectsSafeArea = popupView.configuration.respectsSafeArea
        let centerXAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.centerXAnchor : superView.centerXAnchor
        let centerYAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.centerYAnchor : superView.centerYAnchor
        let leadingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.leadingAnchor : superView.leadingAnchor
        let trailingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.trailingAnchor : superView.trailingAnchor
        let topAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.topAnchor : superView.topAnchor
        let bottomAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.bottomAnchor : superView.bottomAnchor
        layoutConstraints.append(contentView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: center.offsetX))
        layoutConstraints.append(contentView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: center.offsetY))
        if center.hasWidth { layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: center.width)) }
        if center.hasHeight { layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: center.height)) }

        let insets = popupView.configuration.containerConfiguration.screenInsets
        let boundaryConstraints = [
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: insets.left),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -insets.right),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: insets.top),
            contentView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -insets.bottom),
        ]
        boundaryConstraints.forEach { $0.priority = UILayoutPriority(999) }
        layoutConstraints.append(contentsOf: boundaryConstraints)
    }

    private func setupTopLayout(popupView: TFYSwiftPopupView, superView: UIView, contentView: UIView, top: TFYSwiftPopupAnimatorLayoutTop) {
        let respectsSafeArea = popupView.configuration.respectsSafeArea
        let topAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.topAnchor : superView.topAnchor
        let leadingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.leadingAnchor : superView.leadingAnchor
        let trailingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.trailingAnchor : superView.trailingAnchor
        layoutConstraints.append(contentView.topAnchor.constraint(equalTo: topAnchor, constant: top.topMargin))
        layoutConstraints.append(contentView.centerXAnchor.constraint(equalTo: superView.centerXAnchor, constant: top.offsetX))
        if top.hasWidth {
            layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: top.width))
        } else {
            layoutConstraints.append(contentView.leadingAnchor.constraint(equalTo: leadingAnchor))
            layoutConstraints.append(contentView.trailingAnchor.constraint(equalTo: trailingAnchor))
        }
        if top.hasHeight { layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: top.height)) }
    }

    private func setupBottomLayout(popupView: TFYSwiftPopupView, superView: UIView, contentView: UIView, bottom: TFYSwiftPopupAnimatorLayoutBottom) {
        let respectsSafeArea = popupView.configuration.respectsSafeArea
        let bottomAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.bottomAnchor : superView.bottomAnchor
        let leadingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.leadingAnchor : superView.leadingAnchor
        let trailingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.trailingAnchor : superView.trailingAnchor
        layoutConstraints.append(contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottom.bottomMargin))
        layoutConstraints.append(contentView.centerXAnchor.constraint(equalTo: superView.centerXAnchor, constant: bottom.offsetX))
        if bottom.hasWidth {
            layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: bottom.width))
        } else {
            layoutConstraints.append(contentView.leadingAnchor.constraint(equalTo: leadingAnchor))
            layoutConstraints.append(contentView.trailingAnchor.constraint(equalTo: trailingAnchor))
        }
        if bottom.hasHeight { layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: bottom.height)) }
    }

    private func setupLeadingLayout(popupView: TFYSwiftPopupView, superView: UIView, contentView: UIView, leading: TFYSwiftPopupAnimatorLayoutLeading) {
        let respectsSafeArea = popupView.configuration.respectsSafeArea
        let leadingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.leadingAnchor : superView.leadingAnchor
        let centerYAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.centerYAnchor : superView.centerYAnchor
        let topAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.topAnchor : superView.topAnchor
        let bottomAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.bottomAnchor : superView.bottomAnchor
        layoutConstraints.append(contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leading.leadingMargin))
        if leading.hasWidth { layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: leading.width)) }
        if !leading.hasHeight {
            layoutConstraints.append(contentView.topAnchor.constraint(equalTo: topAnchor))
            layoutConstraints.append(contentView.bottomAnchor.constraint(equalTo: bottomAnchor))
        } else {
            layoutConstraints.append(contentView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: leading.offsetY))
            layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: leading.height))
        }
    }

    private func setupTrailingLayout(popupView: TFYSwiftPopupView, superView: UIView, contentView: UIView, trailing: TFYSwiftPopupAnimatorLayoutTrailing) {
        let respectsSafeArea = popupView.configuration.respectsSafeArea
        let trailingAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.trailingAnchor : superView.trailingAnchor
        let centerYAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.centerYAnchor : superView.centerYAnchor
        let topAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.topAnchor : superView.topAnchor
        let bottomAnchor = respectsSafeArea ? superView.safeAreaLayoutGuide.bottomAnchor : superView.bottomAnchor
        layoutConstraints.append(contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailing.trailingMargin))
        if trailing.hasWidth { layoutConstraints.append(contentView.widthAnchor.constraint(equalToConstant: trailing.width)) }
        if !trailing.hasHeight {
            layoutConstraints.append(contentView.topAnchor.constraint(equalTo: topAnchor))
            layoutConstraints.append(contentView.bottomAnchor.constraint(equalTo: bottomAnchor))
        } else {
            layoutConstraints.append(contentView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: trailing.offsetY))
            layoutConstraints.append(contentView.heightAnchor.constraint(equalToConstant: trailing.height))
        }
    }

    private func applyContainerDimensions(
        _ configuration: TFYSwiftPopupContainerConfiguration,
        superView: UIView,
        contentView: UIView
    ) {
        if !layoutProvidesWidth {
            if let constraint = dimensionConstraint(
                configuration.width,
                axis: .width,
                superView: superView,
                contentView: contentView
            ) {
                layoutConstraints.append(constraint)
            }
        }
        if !layoutProvidesHeight,
           let constraint = dimensionConstraint(
               configuration.height,
               axis: .height,
               superView: superView,
               contentView: contentView
           ) {
            layoutConstraints.append(constraint)
        }

        var bounds: [NSLayoutConstraint] = []
        if configuration.hasMinWidth {
            bounds.append(contentView.widthAnchor.constraint(greaterThanOrEqualToConstant: configuration.minWidth))
        }
        if configuration.hasMaxWidth {
            bounds.append(contentView.widthAnchor.constraint(lessThanOrEqualToConstant: configuration.maxWidth))
        }
        if configuration.hasMinHeight {
            bounds.append(contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: configuration.minHeight))
        }
        if configuration.hasMaxHeight {
            bounds.append(contentView.heightAnchor.constraint(lessThanOrEqualToConstant: configuration.maxHeight))
        }
        bounds.forEach { $0.priority = UILayoutPriority(999) }
        layoutConstraints.append(contentsOf: bounds)
    }

    private enum DimensionAxis {
        case width
        case height
    }

    private func dimensionConstraint(
        _ dimension: TFYSwiftPopupContainerDimension,
        axis: DimensionAxis,
        superView: UIView,
        contentView: UIView
    ) -> NSLayoutConstraint? {
        switch dimension.type {
        case .automatic:
            return nil
        case .fixed:
            switch axis {
            case .width: return contentView.widthAnchor.constraint(equalToConstant: dimension.value)
            case .height: return contentView.heightAnchor.constraint(equalToConstant: dimension.value)
            }
        case .ratio:
            switch axis {
            case .width: return contentView.widthAnchor.constraint(equalTo: superView.widthAnchor, multiplier: dimension.value)
            case .height: return contentView.heightAnchor.constraint(equalTo: superView.heightAnchor, multiplier: dimension.value)
            }
        case .custom:
            guard let value = dimension.customHandler?(superView), value.isFinite, value >= 0 else { return nil }
            switch axis {
            case .width: return contentView.widthAnchor.constraint(equalToConstant: value)
            case .height: return contentView.heightAnchor.constraint(equalToConstant: value)
            }
        }
    }

    private var layoutProvidesWidth: Bool {
        switch layout.type {
        case .center: return layout.centerLayout?.hasWidth == true
        case .top, .bottom: return true // Missing width means full-width for these layouts.
        case .leading: return layout.leadingLayout?.hasWidth == true
        case .trailing: return layout.trailingLayout?.hasWidth == true
        case .frame: return true
        }
    }

    private var layoutProvidesHeight: Bool {
        switch layout.type {
        case .center: return layout.centerLayout?.hasHeight == true
        case .top: return layout.topLayout?.hasHeight == true
        case .bottom: return layout.bottomLayout?.hasHeight == true
        case .leading, .trailing: return true // Missing height means full-height for side layouts.
        case .frame: return true
        }
    }
}
