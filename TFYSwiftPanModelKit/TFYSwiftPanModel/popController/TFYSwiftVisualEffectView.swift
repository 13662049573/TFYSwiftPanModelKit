//
//  TFYSwiftVisualEffectView.swift
//  TFYSwiftPanModel
//
//  自定义模糊视图（支持 tint/radius），由 OC TFYVisualEffectView 迁移。
//

import UIKit

private let internalCustomBlurEffectName = "_UICustomBlurEffect"
private let blurEffectColorTintKey = "colorTint"
private let blurEffectColorTintAlphaKey = "colorTintAlpha"
private let blurEffectBlurRadiusKey = "blurRadius"
private let blurEffectScaleKey = "scale"

/// 支持 colorTint、blurRadius 等自定义的 UIVisualEffectView 子类
public final class TFYSwiftVisualEffectView: UIVisualEffectView {

    private var customBlurEffect: UIVisualEffect?

    public var colorTint: UIColor? {
        get { effectValue(forKey: blurEffectColorTintKey) as? UIColor }
        set { setEffectValue(newValue, forKey: blurEffectColorTintKey) }
    }

    public var colorTintAlpha: CGFloat {
        get { CGFloat(truncating: (effectValue(forKey: blurEffectColorTintAlphaKey) as? NSNumber) ?? 0) }
        set { setEffectValue(NSNumber(value: Double(newValue)), forKey: blurEffectColorTintAlphaKey) }
    }

    public var blurRadius: CGFloat {
        get { CGFloat(truncating: (effectValue(forKey: blurEffectBlurRadiusKey) as? NSNumber) ?? 0) }
        set { setEffectValue(NSNumber(value: Double(newValue)), forKey: blurEffectBlurRadiusKey) }
    }

    public var scale: CGFloat {
        get { CGFloat(truncating: (effectValue(forKey: blurEffectScaleKey) as? NSNumber) ?? 1) }
        set { setEffectValue(NSNumber(value: Double(newValue)), forKey: blurEffectScaleKey) }
    }

    private static func defaultEffect() -> UIVisualEffect {
        if let cls = NSClassFromString(internalCustomBlurEffectName) as? NSObject.Type,
           let e = cls.init() as? UIVisualEffect {
            return e
        }
        return UIBlurEffect(style: .light)
    }

    public override init(effect: UIVisualEffect?) {
        let eff = effect ?? TFYSwiftVisualEffectView.defaultEffect()
        super.init(effect: eff)
        customBlurEffect = eff
    }

    public convenience init() {
        let eff = TFYSwiftVisualEffectView.defaultEffect()
        self.init(effect: eff)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func effectValue(forKey key: String) -> Any? {
        guard let eff = customBlurEffect,
              String(describing: Swift.type(of: eff)) == internalCustomBlurEffectName else {
            return nil
        }
        return (eff as NSObject).value(forKey: key)
    }

    private func setEffectValue(_ value: Any?, forKey key: String) {
        guard let eff = customBlurEffect,
              String(describing: Swift.type(of: eff)) == internalCustomBlurEffectName else {
            effect = customBlurEffect
            return
        }
        (eff as NSObject).setValue(value, forKey: key)
        effect = customBlurEffect
    }

    public func updateBlurEffect(_ newEffect: UIVisualEffect?) {
        guard let newEffect else { return }
        customBlurEffect = newEffect
        self.effect = newEffect
        setNeedsDisplay()
        layoutIfNeeded()
    }
}
