//
//  TFYSwiftPanIndicatorView.swift
//  TFYSwiftPanModel
//
//  PanModal 拖拽指示器视图，由 OC TFYPanIndicatorView 迁移。
//

import UIKit

/// PanModal 拖拽指示器视图
public final class TFYSwiftPanIndicatorView: UIView, TFYSwiftPanModalIndicatorProtocol {

    public var indicatorColor: UIColor = UIColor(red: 0.792, green: 0.788, blue: 0.812, alpha: 1) {
        didSet {
            leftView.backgroundColor = indicatorColor
            rightView.backgroundColor = indicatorColor
        }
    }

    private let leftView = UIView()
    private let rightView = UIView()
    private var state: TFYIndicatorState = .normal

    public override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(leftView)
        addSubview(rightView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func animate(_ animations: @escaping () -> Void) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [.beginFromCurrentState, .curveEaseOut], animations: animations)
    }

    // MARK: - TFYSwiftPanModalIndicatorProtocol
    public func didChange(to state: TFYIndicatorState) {
        guard self.state != state else { return }
        self.state = state
        switch state {
        case .normal:
            let angle = 20 * CGFloat.pi / 180
            animate {
                self.leftView.transform = CGAffineTransform(rotationAngle: angle)
                self.rightView.transform = CGAffineTransform(rotationAngle: -angle)
            }
        case .pullDown:
            animate {
                self.leftView.transform = .identity
                self.rightView.transform = .identity
            }
        }
    }

    public func indicatorSize() -> CGSize {
        CGSize(width: 34, height: 13)
    }

    public func setupSubviews() {
        let size = indicatorSize()
        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: size.width, height: size.height)
        let height: CGFloat = 5
        let correction = height / 2
        leftView.frame = CGRect(x: 0, y: 0, width: frame.width / 2 + correction, height: height)
        leftView.panCenterY = panHeight / 2
        leftView.layer.cornerRadius = min(leftView.panWidth, leftView.panHeight) / 2
        rightView.frame = CGRect(x: frame.width / 2 - correction, y: 0, width: frame.width / 2 + correction, height: height)
        rightView.panCenterY = panHeight / 2
        rightView.layer.cornerRadius = min(rightView.panWidth, rightView.panHeight) / 2
    }
}
