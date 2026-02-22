//
//  TFYSwiftDimmedView.swift
//  TFYSwiftPanModel
//
//  PanModal 背景遮罩视图，由 OC TFYDimmedView 迁移。
//

import UIKit

/// 遮罩显示状态
public enum DimState: Int {
    case max = 0
    case off
    case percent
}

/// PanModal 弹窗背景遮罩视图
public final class TFYSwiftDimmedView: UIView {

    public var dimState: DimState = .off {
        didSet { updateAlpha() }
    }

    public var percent: CGFloat = 1 {
        didSet { updateAlpha() }
    }

    public var tapBlock: ((UITapGestureRecognizer) -> Void)?

    public var blurTintColor: UIColor? {
        didSet { blurView.colorTint = blurTintColor }
    }

    public private(set) var backgroundConfig: TFYSwiftBackgroundConfig

    private let backgroundView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.alpha = 0
        v.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0, alpha: 0.6) : .black
        }
        return v
    }()

    private let blurView = TFYSwiftVisualEffectView()
    private var maxDimAlpha: CGFloat = 0.7
    private var maxBlurRadius: CGFloat = 0
    private var maxBlurTintAlpha: CGFloat = 0.5
    private var isBlurMode: Bool = false
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapView))

    public init(dimAlpha: CGFloat, blurRadius: CGFloat) {
        self.backgroundConfig = TFYSwiftBackgroundConfig()
        super.init(frame: .zero)
        maxBlurRadius = blurRadius
        maxDimAlpha = dimAlpha
        commonInit()
    }

    public override init(frame: CGRect) {
        self.backgroundConfig = TFYSwiftBackgroundConfig()
        super.init(frame: frame)
        maxDimAlpha = 0.7
        commonInit()
    }

    public init(backgroundConfig: TFYSwiftBackgroundConfig) {
        self.backgroundConfig = backgroundConfig
        super.init(frame: .zero)
        maxDimAlpha = backgroundConfig.backgroundAlpha
        maxBlurRadius = backgroundConfig.backgroundBlurRadius
        blurTintColor = backgroundConfig.blurTintColor
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        isBlurMode = maxBlurRadius > 0 || backgroundConfig.visualEffect != nil
        addGestureRecognizer(tapGesture)
        isAccessibilityElement = true
        accessibilityLabel = "弹窗背景遮罩"
        accessibilityTraits = .button
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        if isBlurMode {
            blurView.isUserInteractionEnabled = false
            addSubview(blurView)
            configBlurView()
        } else {
            addSubview(backgroundView)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
        backgroundView.frame = bounds
        if UIDevice.current.userInterfaceIdiom == .pad {
            let insets = safeAreaInsets
            blurView.frame = bounds.inset(by: insets)
            backgroundView.frame = bounds.inset(by: insets)
        }
    }

    @objc private func didTapView() {
        tapBlock?(tapGesture)
    }

    public func reloadConfig(_ config: TFYSwiftBackgroundConfig) {
        let currentState = dimState
        let currentPercent = percent
        subviews.forEach { $0.removeFromSuperview() }
        backgroundConfig = config
        maxDimAlpha = config.backgroundAlpha
        maxBlurRadius = config.backgroundBlurRadius
        blurTintColor = config.blurTintColor
        isBlurMode = maxBlurRadius > 0 || config.visualEffect != nil
        setupView()
        dimState = currentState
        percent = currentPercent
    }

    private func updateAlpha() {
        var alpha: CGFloat = 0
        var blurRadius: CGFloat = 0
        var blurTintAlpha: CGFloat = 0
        switch dimState {
        case .max:
            alpha = maxDimAlpha
            blurRadius = maxBlurRadius
            blurTintAlpha = maxBlurTintAlpha
        case .percent:
            let p = max(0, min(1, percent))
            alpha = maxDimAlpha * p
            blurRadius = maxBlurRadius * p
            blurTintAlpha = maxBlurTintAlpha * p
        case .off:
            break
        }
        if isBlurMode {
            if backgroundConfig.visualEffect != nil {
                blurView.alpha = alpha
                blurView.isHidden = alpha <= 0
                blurView.setNeedsDisplay()
            } else {
                blurView.blurRadius = blurRadius
                blurView.colorTintAlpha = blurTintAlpha
            }
        } else {
            backgroundView.alpha = alpha
        }
    }

    private func configBlurView() {
        if let eff = backgroundConfig.visualEffect {
            blurView.updateBlurEffect(eff)
        } else {
            blurView.colorTint = .white
            blurView.colorTintAlpha = maxBlurTintAlpha
            blurView.isUserInteractionEnabled = false
        }
    }
}
