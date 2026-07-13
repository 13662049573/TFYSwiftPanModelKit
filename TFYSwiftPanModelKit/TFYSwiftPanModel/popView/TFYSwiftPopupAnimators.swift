//
//  TFYSwiftPopupAnimators.swift
//  TFYSwiftPanModel
//
//  弹窗具体动画器集合，由 OC TFYPopupAnimators 迁移。
//

import UIKit

// MARK: - FadeInOut

public final class TFYSwiftPopupFadeInOutAnimator: TFYSwiftPopupBaseAnimator {
    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        contentView.alpha = 0
        backgroundView.alpha = 0
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 1
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 0
            backgroundView?.alpha = 0
        }
    }
}

// MARK: - ZoomInOut

public final class TFYSwiftPopupZoomInOutAnimator: TFYSwiftPopupBaseAnimator {
    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 1
            contentView?.transform = .identity
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 0
            contentView?.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            backgroundView?.alpha = 0
        }
    }
}

// MARK: - 3D Flip

public final class TFYSwiftPopup3DFlipAnimator: TFYSwiftPopupBaseAnimator {
    public override init() {
        super.init()
        displayDuration = 0.6
        dismissDuration = 0.6
    }

    private func makeFlipTransform() -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 500.0
        return CATransform3DRotate(transform, .pi, 0, 1, 0)
    }

    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.layer.transform = makeFlipTransform()
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 1
            contentView?.layer.transform = CATransform3DIdentity
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak self, weak contentView, weak backgroundView] in
            guard let self else { return }
            contentView?.alpha = 0
            contentView?.layer.transform = self.makeFlipTransform()
            backgroundView?.alpha = 0
        }
    }
}

// MARK: - Spring

public final class TFYSwiftPopupSpringAnimator: TFYSwiftPopupBaseAnimator {
    public override init() {
        super.init()
        displaySpringDampingRatio = 0.7
        hasDisplaySpringDampingRatio = true
        displaySpringVelocity = 0.5
        hasDisplaySpringVelocity = true
        dismissSpringDampingRatio = 0.8
        hasDismissSpringDampingRatio = true
        dismissSpringVelocity = 0.3
        hasDismissSpringVelocity = true
        displayDuration = 0.5
        dismissDuration = 0.5
    }

    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 1
            contentView?.transform = .identity
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 0
            contentView?.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            backgroundView?.alpha = 0
        }
    }
}

// MARK: - Bounce

public final class TFYSwiftPopupBounceAnimator: TFYSwiftPopupBaseAnimator {
    public override init() {
        super.init()
        displaySpringDampingRatio = 0.6
        hasDisplaySpringDampingRatio = true
        displaySpringVelocity = 0.8
        hasDisplaySpringVelocity = true
        dismissSpringDampingRatio = 0.8
        hasDismissSpringDampingRatio = true
        dismissSpringVelocity = 0.5
        hasDismissSpringVelocity = true
        displayDuration = 0.6
        dismissDuration = 0.6
    }

    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 1
            contentView?.transform = .identity
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 0
            contentView?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            backgroundView?.alpha = 0
        }
    }
}

// MARK: - Rotate

public final class TFYSwiftPopupRotateAnimator: TFYSwiftPopupBaseAnimator {
    public override init() {
        super.init()
        displayDuration = 0.8
        dismissDuration = 0.8
    }

    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        contentView.alpha = 0
        backgroundView.alpha = 0
        contentView.transform = CGAffineTransform(rotationAngle: -.pi)
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 1
            contentView?.transform = .identity
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 0
            contentView?.transform = CGAffineTransform(rotationAngle: .pi)
            backgroundView?.alpha = 0
        }
    }
}

// MARK: - Directional (base + Up/Down/Left/Right)

public class TFYSwiftPopupDirectionalAnimator: TFYSwiftPopupBaseAnimator {
    public func getInitialTransform(popupView: TFYSwiftPopupView, contentView: UIView) -> CGAffineTransform {
        .identity
    }

    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        let initial = getInitialTransform(popupView: popupView, contentView: contentView)
        contentView.transform = initial
        contentView.alpha = 0
        backgroundView.alpha = 0
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.transform = .identity
            contentView?.alpha = 1
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.transform = initial
            contentView?.alpha = 0
            backgroundView?.alpha = 0
        }
    }
}

public final class TFYSwiftPopupUpwardAnimator: TFYSwiftPopupDirectionalAnimator {
    public override func getInitialTransform(popupView: TFYSwiftPopupView, contentView: UIView) -> CGAffineTransform {
        CGAffineTransform(translationX: 0, y: popupView.bounds.height)
    }
}

public final class TFYSwiftPopupDownwardAnimator: TFYSwiftPopupDirectionalAnimator {
    public override func getInitialTransform(popupView: TFYSwiftPopupView, contentView: UIView) -> CGAffineTransform {
        CGAffineTransform(translationX: 0, y: -popupView.bounds.height)
    }
}

public final class TFYSwiftPopupLeftwardAnimator: TFYSwiftPopupDirectionalAnimator {
    public override func getInitialTransform(popupView: TFYSwiftPopupView, contentView: UIView) -> CGAffineTransform {
        CGAffineTransform(translationX: popupView.bounds.width, y: 0)
    }
}

public final class TFYSwiftPopupRightwardAnimator: TFYSwiftPopupDirectionalAnimator {
    public override func getInitialTransform(popupView: TFYSwiftPopupView, contentView: UIView) -> CGAffineTransform {
        CGAffineTransform(translationX: -popupView.bounds.width, y: 0)
    }
}

// MARK: - Slide

public enum TFYPopupSlideDirection: UInt {
    case fromTop = 0
    case fromBottom
    case fromLeft
    case fromRight
}

public final class TFYSwiftPopupSlideAnimator: TFYSwiftPopupBaseAnimator {
    public let direction: TFYPopupSlideDirection

    public init(direction: TFYPopupSlideDirection) {
        self.direction = direction
        super.init(layout: TFYSwiftPopupAnimatorLayout.center(TFYSwiftPopupAnimatorLayoutCenter.default()))
    }

    public init(direction: TFYPopupSlideDirection, layout: TFYSwiftPopupAnimatorLayout) {
        self.direction = direction
        super.init(layout: layout)
    }

    public override func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {
        super.setup(popupView: popupView, contentView: contentView, backgroundView: backgroundView)
        contentView.alpha = 0
        backgroundView.alpha = 0
        let bounds = contentView.superview?.bounds ?? popupView.bounds
        let initial: CGAffineTransform
        switch direction {
        case .fromTop: initial = CGAffineTransform(translationX: 0, y: -bounds.height)
        case .fromBottom: initial = CGAffineTransform(translationX: 0, y: bounds.height)
        case .fromLeft: initial = CGAffineTransform(translationX: -bounds.width, y: 0)
        case .fromRight: initial = CGAffineTransform(translationX: bounds.width, y: 0)
        }
        contentView.transform = initial
        let dir = direction
        displayAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 1
            contentView?.transform = .identity
            backgroundView?.alpha = 1
        }
        dismissAnimationBlock = { [weak contentView, weak backgroundView] in
            contentView?.alpha = 0
            switch dir {
            case .fromTop: contentView?.transform = CGAffineTransform(translationX: 0, y: -bounds.height)
            case .fromBottom: contentView?.transform = CGAffineTransform(translationX: 0, y: bounds.height)
            case .fromLeft: contentView?.transform = CGAffineTransform(translationX: -bounds.width, y: 0)
            case .fromRight: contentView?.transform = CGAffineTransform(translationX: bounds.width, y: 0)
            }
            backgroundView?.alpha = 0
        }
    }
}
