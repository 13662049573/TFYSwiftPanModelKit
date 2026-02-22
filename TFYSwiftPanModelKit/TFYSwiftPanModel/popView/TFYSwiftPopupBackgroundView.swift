//
//  TFYSwiftPopupBackgroundView.swift
//  TFYSwiftPanModel
//
//  弹窗背景视图，由 OC TFYPopupBackgroundView 迁移。
//

import UIKit

/// 自定义背景效果闭包
public typealias TFYPopupBackgroundCustomHandler = (TFYSwiftPopupBackgroundView) -> Void

/// 弹窗背景视图
public final class TFYSwiftPopupBackgroundView: UIControl {
    public var style: TFYPopupBackgroundStyle = .solidColor {
        didSet { if style != oldValue { refreshBackgroundStyle() } }
    }
    public var color: UIColor = UIColor.black.withAlphaComponent(0.3) {
        didSet {
            if color != oldValue, style == .solidColor { backgroundColor = color }
        }
    }
    public var blurEffectStyle: UIBlurEffect.Style = .dark {
        didSet {
            if blurEffectStyle != oldValue, style == .blur { refreshBackgroundStyle() }
        }
    }
    public var gradientColors: [UIColor] = [
        UIColor.black.withAlphaComponent(0.5),
        UIColor.black.withAlphaComponent(0.3)
    ] {
        didSet { if style == .gradient { refreshBackgroundStyle() } }
    }
    public var gradientLocations: [NSNumber]? = [0.0, 1.0] {
        didSet { if style == .gradient { refreshBackgroundStyle() } }
    }
    public var gradientStartPoint: CGPoint = CGPoint(x: 0.5, y: 0) {
        didSet { if style == .gradient { refreshBackgroundStyle() } }
    }
    public var gradientEndPoint: CGPoint = CGPoint(x: 0.5, y: 1) {
        didSet { if style == .gradient { refreshBackgroundStyle() } }
    }

    private var effectView: UIVisualEffectView?
    private var gradientLayer: CAGradientLayer?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        layer.allowsGroupOpacity = false
        refreshBackgroundStyle()
    }

    private func refreshBackgroundStyle() {
        effectView?.removeFromSuperview()
        effectView = nil
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil

        switch style {
        case .solidColor:
            backgroundColor = color
        case .blur:
            let ev = UIVisualEffectView(effect: UIBlurEffect(style: blurEffectStyle))
            ev.frame = bounds
            insertSubview(ev, at: 0)
            effectView = ev
        case .gradient:
            let gl = CAGradientLayer()
            gl.frame = bounds
            gl.colors = gradientColors.map { $0.cgColor }
            gl.locations = gradientLocations
            gl.startPoint = gradientStartPoint
            gl.endPoint = gradientEndPoint
            layer.insertSublayer(gl, at: 0)
            gradientLayer = gl
        case .custom:
            break
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        effectView?.frame = bounds
        gradientLayer?.frame = bounds
    }

    public func applyBackgroundEffect(_ effect: TFYPopupBackgroundEffect, customHandler: TFYPopupBackgroundCustomHandler?) {
        switch effect {
        case .none:
            backgroundColor = .clear
        case .blur:
            applyBlurEffect(.dark)
        case .gradient:
            applyGradientEffect(colors: [
                UIColor.black.withAlphaComponent(0.5),
                UIColor.black.withAlphaComponent(0.3)
            ], locations: [0.0, 1.0])
        case .dimmed:
            applyDimmedEffect(color: .black, alpha: 0.3)
        case .custom:
            customHandler?(self)
        }
    }

    public func applyBlurEffect(_ style: UIBlurEffect.Style) {
        effectView?.removeFromSuperview()
        effectView = nil
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
        effectView = blurView
    }

    public func applyGradientEffect(colors: [UIColor], locations: [CGFloat]?) {
        gradientLayer?.removeFromSuperlayer()
        gradientLayer = nil
        guard !colors.isEmpty else { return }
        let gl = CAGradientLayer()
        gl.frame = bounds
        gl.colors = colors.map { $0.cgColor }
        gl.locations = locations?.map { NSNumber(value: Double($0)) }
        layer.insertSublayer(gl, at: 0)
        gradientLayer = gl
    }

    public func applyDimmedEffect(color: UIColor, alpha: CGFloat) {
        backgroundColor = color.withAlphaComponent(alpha)
    }
}
