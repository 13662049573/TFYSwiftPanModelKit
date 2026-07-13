//
//  DemoPopupModels.swift
//  TFYSwiftPanModelKit
//
//  presentPopup / 高级 Popup 功能对应的 Demo 模型
//

import UIKit

// MARK: - 通用 presentPopup 内容 VC

final class DemoPopupContentVC: TFYSwiftPopupContentViewController {

    enum Style: String {
        case fade = "Fade 控制器弹窗"
        case zoom = "Zoom 控制器弹窗"
        case spring = "Spring 控制器弹窗"
        case bounce = "Bounce 控制器弹窗"
        case flip = "3D Flip 控制器弹窗"
        case rotate = "Rotate 控制器弹窗"
        case slideBottom = "底部滑入控制器"
        case slideTop = "顶部滑入控制器"
        case slideLeft = "左侧滑入控制器"
        case slideRight = "右侧滑入控制器"
    }

    private let style: Style

    init(style: Style) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = CGSize(width: 300, height: 220)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        installStack(
            title: style.rawValue,
            detail: "任意 UIViewController\n可通过 presentPopup 弹出\nisPresentedAsPopup=\(isPresentedAsPopup)"
        )
    }

    override func preferredPopupContentSize() -> CGSize {
        switch style {
        case .slideBottom, .slideTop:
            return CGSize(width: 0, height: 300)
        case .slideLeft, .slideRight:
            return CGSize(width: 280, height: 0)
        default:
            return CGSize(width: 300, height: 220)
        }
    }

    override func preferredPopupAnimator() -> TFYSwiftPopupViewAnimator? {
        switch style {
        case .fade: return TFYSwiftPopupFadeInOutAnimator()
        case .zoom: return TFYSwiftPopupZoomInOutAnimator()
        case .spring: return TFYSwiftPopupSpringAnimator()
        case .bounce: return TFYSwiftPopupBounceAnimator()
        case .flip: return TFYSwiftPopup3DFlipAnimator()
        case .rotate: return TFYSwiftPopupRotateAnimator()
        case .slideBottom:
            let layout = TFYSwiftPopupAnimatorLayout.bottom(
                TFYSwiftPopupAnimatorLayoutBottom.layout(bottomMargin: 0, offsetX: 0, height: 300)
            )
            return TFYSwiftPopupSlideAnimator(direction: .fromBottom, layout: layout)
        case .slideTop:
            let layout = TFYSwiftPopupAnimatorLayout.top(
                TFYSwiftPopupAnimatorLayoutTop.layout(topMargin: 0, offsetX: 0, height: 300)
            )
            return TFYSwiftPopupSlideAnimator(direction: .fromTop, layout: layout)
        case .slideLeft:
            let layout = TFYSwiftPopupAnimatorLayout.leading(
                TFYSwiftPopupAnimatorLayoutLeading.layout(leadingMargin: 0, offsetY: 0, width: 280)
            )
            return TFYSwiftPopupSlideAnimator(direction: .fromLeft, layout: layout)
        case .slideRight:
            let layout = TFYSwiftPopupAnimatorLayout.trailing(
                TFYSwiftPopupAnimatorLayoutTrailing.layout(trailingMargin: 0, offsetY: 0, width: 280)
            )
            return TFYSwiftPopupSlideAnimator(direction: .fromRight, layout: layout)
        }
    }

    override func preferredPopupLayout() -> TFYSwiftPopupAnimatorLayout? {
        switch style {
        case .slideBottom:
            return .bottom(TFYSwiftPopupAnimatorLayoutBottom.layout(bottomMargin: 0, offsetX: 0, height: 300))
        case .slideTop:
            return .top(TFYSwiftPopupAnimatorLayoutTop.layout(topMargin: 0, offsetX: 0, height: 300))
        case .slideLeft:
            return .leading(TFYSwiftPopupAnimatorLayoutLeading.layout(leadingMargin: 0, offsetY: 0, width: 280))
        case .slideRight:
            return .trailing(TFYSwiftPopupAnimatorLayoutTrailing.layout(trailingMargin: 0, offsetY: 0, width: 280))
        default:
            return .center(TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 220))
        }
    }

    private func installStack(title: String, detail: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center

        let desc = UILabel()
        desc.text = detail
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.addAction(UIAction { [weak self] _ in self?.dismissPopup() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, desc, btn])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }
}

// MARK: - 模糊背景 + Bounce

final class DemoConfiguredPopupContentVC: TFYSwiftPopupContentViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemBackground
        let title = UILabel()
        title.text = "自定义配置 VC 弹窗"
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "模糊背景 + Bounce 动画\n继承 TFYSwiftPopupContentViewController"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.addAction(UIAction { [weak self] _ in self?.dismissPopup() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, btn])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
        ])
    }

    override func preferredPopupContentSize() -> CGSize { CGSize(width: 300, height: 240) }

    override func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.backgroundStyle = .blur
        config.cornerRadius = 20
        config.enableHapticFeedback = true
        config.dismissOnBackgroundTap = true
        config.enablePriorityManagement = false
        return config
    }

    override func preferredPopupAnimator() -> TFYSwiftPopupViewAnimator? {
        TFYSwiftPopupBounceAnimator()
    }
}

// MARK: - 不可关闭（仅代码关闭）

final class DemoNonDismissiblePopupVC: TFYSwiftPopupContentViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "不可手势关闭"
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "isDismissible = false\n背景点击/拖拽无效\n只能点按钮关闭"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let btn = UIButton(type: .system)
        btn.setTitle("代码关闭", for: .normal)
        btn.addAction(UIAction { [weak self] _ in self?.dismissPopup() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, btn])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func preferredPopupContentSize() -> CGSize { CGSize(width: 300, height: 220) }

    override func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.isDismissible = false
        config.dismissOnBackgroundTap = false
        config.enableDragToDismiss = false
        config.enableSwipeToDismiss = false
        config.cornerRadius = 16
        config.enablePriorityManagement = false
        return config
    }

    override func preferredPopupAnimator() -> TFYSwiftPopupViewAnimator? {
        TFYSwiftPopupZoomInOutAnimator()
    }

    override func shouldAllowPopupDismiss() -> Bool { true }
}

// MARK: - 拖拽 / 滑动关闭

final class DemoDragSwipePopupVC: TFYSwiftPopupContentViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "拖拽 / 滑动关闭"
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "向下拖拽或左右滑动关闭\nenableDragToDismiss / enableSwipeToDismiss"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let btn = UIButton(type: .system)
        btn.setTitle("按钮关闭", for: .normal)
        btn.addAction(UIAction { [weak self] _ in self?.dismissPopup() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, btn])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func preferredPopupContentSize() -> CGSize { CGSize(width: 300, height: 220) }

    override func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.enableDragToDismiss = true
        config.enableSwipeToDismiss = true
        config.dragDismissThreshold = 0.25
        config.cornerRadius = 16
        config.enablePriorityManagement = false
        return config
    }

    override func preferredPopupAnimator() -> TFYSwiftPopupViewAnimator? {
        TFYSwiftPopupBounceAnimator()
    }
}

// MARK: - 键盘避让

final class DemoKeyboardPopupVC: TFYSwiftPopupContentViewController {

    private let mode: TFYPopupKeyboardAvoidingMode

    init(mode: TFYPopupKeyboardAvoidingMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let modeName: String
        switch mode {
        case .transform: modeName = "transform"
        case .constraint: modeName = "constraint"
        case .resize: modeName = "resize"
        }

        let title = UILabel()
        title.text = "键盘避让 (\(modeName))"
        title.font = .boldSystemFont(ofSize: 17)
        title.textAlignment = .center

        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "点击输入，观察键盘避让"
        field.translatesAutoresizingMaskIntoConstraints = false

        let btn = UIButton(type: .system)
        btn.setTitle("关闭并收起键盘", for: .normal)
        btn.addAction(UIAction { [weak self] _ in
            self?.view.endEditing(true)
            self?.dismissPopup()
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, field, btn])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            field.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    override func preferredPopupContentSize() -> CGSize { CGSize(width: 320, height: 220) }

    override func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.cornerRadius = 16
        config.keyboardConfiguration.isEnabled = true
        config.keyboardConfiguration.avoidingMode = mode
        config.keyboardConfiguration.additionalOffset = 12
        config.enablePriorityManagement = false
        return config
    }

    override func preferredPopupAnimator() -> TFYSwiftPopupViewAnimator? {
        TFYSwiftPopupSpringAnimator()
    }
}

// MARK: - 穿透背景

final class DemoPenetrablePopupVC: TFYSwiftPopupContentViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        view.layer.cornerRadius = 16

        let title = UILabel()
        title.text = "穿透背景"
        title.textColor = .white
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "isPenetrable = true\n背景不拦截点击\n可点击下层界面"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = UIColor.white.withAlphaComponent(0.9)

        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.tintColor = .white
        btn.addAction(UIAction { [weak self] _ in self?.dismissPopup() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, btn])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func preferredPopupContentSize() -> CGSize { CGSize(width: 260, height: 180) }

    override func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.isPenetrable = true
        config.dismissOnBackgroundTap = false
        config.backgroundStyle = .solidColor
        config.backgroundColor = .clear
        config.cornerRadius = 16
        config.enablePriorityManagement = false
        return config
    }
}

// MARK: - 自动关闭

final class DemoAutoDismissPopupVC: TFYSwiftPopupContentViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "自动关闭"
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "autoDismissDelay = 2s\n两秒后自动消失"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [title, desc])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func preferredPopupContentSize() -> CGSize { CGSize(width: 260, height: 160) }

    override func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.autoDismissDelay = 2
        config.cornerRadius = 16
        config.enableHapticFeedback = true
        config.enablePriorityManagement = false
        return config
    }

    override func preferredPopupAnimator() -> TFYSwiftPopupViewAnimator? {
        TFYSwiftPopupFadeInOutAnimator()
    }
}

// MARK: - 无障碍

final class DemoAccessibilityPopupVC: TFYSwiftPopupContentViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.accessibilityLabel = "无障碍演示弹窗"

        let title = UILabel()
        title.text = "无障碍 Popup"
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "enableAccessibility = true\nVoiceOver 可聚焦弹窗内容"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.accessibilityLabel = "关闭弹窗"
        btn.addAction(UIAction { [weak self] _ in self?.dismissPopup() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, btn])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func preferredPopupContentSize() -> CGSize { CGSize(width: 300, height: 200) }

    override func preferredPopupConfiguration() -> TFYSwiftPopupViewConfiguration {
        let config = TFYSwiftPopupViewConfiguration()
        config.enableAccessibility = true
        config.cornerRadius = 16
        config.backgroundStyle = .blur
        config.enablePriorityManagement = false
        return config
    }
}
