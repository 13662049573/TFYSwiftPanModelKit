//
//  DemoPanModalViewController.swift
//  TFYSwiftPanModelKit
//

import UIKit

// MARK: - 基础 PanModal 弹窗

final class DemoPanModalVC: UIViewController {

    enum Mode { case short, medium, long }
    private let mode: Mode
    private let presentingStyle: PresentingViewControllerAnimationStyle
    private let locksInteractiveDismissal: Bool
    private let statusLabel = UILabel()

    init(
        mode: Mode,
        presentingStyle: PresentingViewControllerAnimationStyle = .none,
        locksInteractiveDismissal: Bool = false
    ) {
        self.mode = mode
        self.presentingStyle = presentingStyle
        self.locksInteractiveDismissal = locksInteractiveDismissal
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let modeText: String
        switch mode {
        case .short: modeText = "Short 弹窗 (250pt)"
        case .medium: modeText = "Medium 弹窗 (400pt)"
        case .long: modeText = "Long 全屏弹窗"
        }
        let title = UILabel()
        title.text = modeText
        title.font = .boldSystemFont(ofSize: 20)
        title.textAlignment = .center

        let desc = UILabel()
        var features = ["拖拽或按钮切换 Short / Medium / Long"]
        if presentingStyle != .none { features.append("父页面动画：\(presentingStyle.demoName)") }
        if locksInteractiveDismissal { features.append("背景与手势关闭已锁定") }
        desc.text = features.joined(separator: "\n")
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let stateStack = UIStackView()
        stateStack.axis = .horizontal
        stateStack.spacing = 8
        stateStack.distribution = .fillEqually
        for (title, state) in [("Short", PresentationState.short), ("Medium", .medium), ("Long", .long)] {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.backgroundColor = .tertiarySystemFill
            button.layer.cornerRadius = 8
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                self.statusLabel.text = "正在切换：\(state.demoName)"
                self.panModalTransition(to: state)
                DispatchQueue.main.asyncAfter(deadline: .now() + self.transitionDuration()) {
                    self.statusLabel.text = "当前状态：\(self.panPresentationState.demoName)"
                }
            }, for: .touchUpInside)
            stateStack.addArrangedSubview(button)
        }

        statusLabel.text = "当前状态：准备展示"
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .systemIndigo
        statusLabel.textAlignment = .center

        let btn = UIButton(type: .system)
        btn.setTitle(locksInteractiveDismissal ? "代码关闭（唯一出口）" : "关闭", for: .normal)
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, stateStack, statusLabel, btn])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    @objc private func close() { dismiss(animated: true) }

    override func shortFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 250) }

    override func mediumFormHeight() -> PanModalHeight {
        switch mode {
        case .short: return PanModalHeight(type: .content, height: 250)
        case .medium, .long: return PanModalHeight(type: .content, height: 400)
        }
    }

    override func longFormHeight() -> PanModalHeight {
        switch mode {
        case .short: return PanModalHeight(type: .content, height: 250)
        case .medium: return PanModalHeight(type: .content, height: 400)
        case .long: return PanModalHeight(type: .max, height: 0)
        }
    }

    override func originPresentationState() -> PresentationState {
        switch mode {
        case .short: return .short
        case .medium: return .medium
        case .long: return .long
        }
    }

    override func presentingVCAnimationStyle() -> PresentingViewControllerAnimationStyle { presentingStyle }
    override func allowsTapBackgroundToDismiss() -> Bool { !locksInteractiveDismissal }
    override func allowsDragToDismiss() -> Bool { !locksInteractiveDismissal }
    override func allowsPullDownWhenShortState() -> Bool { !locksInteractiveDismissal }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        statusLabel.text = "当前状态：\(panPresentationState.demoName)"
    }
}

private extension PresentationState {
    var demoName: String {
        switch self {
        case .short: return "Short"
        case .medium: return "Medium"
        case .long: return "Long"
        }
    }
}

private extension PresentingViewControllerAnimationStyle {
    var demoName: String {
        switch self {
        case .none: return "None"
        case .pageSheet: return "PageSheet"
        case .shoppingCart: return "ShoppingCart"
        case .custom: return "Custom"
        }
    }
}

final class DemoPanModalKeyboardVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "PanModal 键盘避让"
        title.font = .preferredFont(forTextStyle: .title2)
        title.textAlignment = .center
        let field = UITextField()
        field.borderStyle = .roundedRect
        field.placeholder = "点击输入，观察面板自动上移"
        let close = UIButton(type: .system)
        close.setTitle("收起键盘并关闭", for: .normal)
        close.addAction(UIAction { [weak self] _ in
            self?.view.endEditing(true)
            self?.dismiss(animated: true)
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, field, close])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            field.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    override func shortFormHeight() -> PanModalHeight { .init(type: .content, height: 280) }
    override func longFormHeight() -> PanModalHeight { .init(type: .content, height: 460) }
    override func originPresentationState() -> PresentationState { .short }
    override func isAutoHandleKeyboardEnabled() -> Bool { true }
    override func keyboardOffsetFromInputView() -> CGFloat { 12 }
}

// MARK: - 带 ScrollView 的弹窗

final class DemoScrollableVC: UIViewController, UITableViewDataSource {

    private let tableView = UITableView()
    private let items = (1...50).map { "列表项 \($0)" }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let header = UILabel()
        header.text = "ScrollView 弹窗"
        header.font = .boldSystemFont(ofSize: 20)
        header.textAlignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "C")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func panScrollable() -> UIScrollView? { tableView }
    override func shortFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 300) }
    override func longFormHeight() -> PanModalHeight { PanModalHeight(type: .max, height: 0) }
    override func originPresentationState() -> PresentationState { .short }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "C", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

// MARK: - 自定义样式弹窗

final class DemoCustomStyleVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.1)
        let title = UILabel()
        title.text = "自定义样式弹窗"
        title.font = .boldSystemFont(ofSize: 22)
        title.textColor = .systemIndigo
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "• 自定义背景模糊效果\n• 圆角 20pt\n• 带阴影\n• 拖拽切换高度"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [title, desc])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
        ])
    }

    override func shortFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 300) }
    override func longFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 500) }
    override func cornerRadius() -> CGFloat { 20 }

    override func backgroundConfig() -> TFYSwiftBackgroundConfig {
        let c = TFYSwiftBackgroundConfig.config(behavior: .customBlurEffect)
        c.backgroundAlpha = 0.5
        c.backgroundBlurRadius = 10
        return c
    }

    override func contentShadow() -> TFYSwiftPanModalShadow {
        TFYSwiftPanModalShadow(color: .black.withAlphaComponent(0.3), radius: 12, offset: CGSize(width: 0, height: -4), opacity: 0.4)
    }

    override func originPresentationState() -> PresentationState { .short }
}

// MARK: - 边缘滑动关闭弹窗

final class DemoEdgeInteractiveVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "边缘滑动关闭"
        title.font = .boldSystemFont(ofSize: 20)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "从屏幕左边缘向右滑动可关闭弹窗\n同时支持下拉关闭与触觉反馈"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [title, desc])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    override func shortFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 280) }
    override func longFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 450) }
    override func allowScreenEdgeInteractive() -> Bool { true }
    override func maxAllowedDistanceToLeftScreenEdgeForPanInteraction() -> CGFloat { 30 }
    override func isHapticFeedbackEnabled() -> Bool { true }
    override func originPresentationState() -> PresentationState { .short }
}

// MARK: - 防频繁点击演示

final class DemoFrequentTapVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "防频繁点击"
        title.font = .boldSystemFont(ofSize: 20)
        title.textAlignment = .center

        let desc = UILabel()
        desc.text = "快速连续点击列表入口会触发节流\nshouldPreventFrequentTapping = true\n间隔 1.5 秒"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, btn])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    override func shortFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 260) }
    override func longFormHeight() -> PanModalHeight { PanModalHeight(type: .content, height: 260) }
    override func shouldPreventFrequentTapping() -> Bool { true }
    override func frequentTapPreventionInterval() -> TimeInterval { 1.5 }
    override func shouldShowFrequentTapPreventionHint() -> Bool { true }
    override func frequentTapPreventionHintText() -> String? { "点击太快了，请稍后再试" }
    override func isHapticFeedbackEnabled() -> Bool { true }
    override func originPresentationState() -> PresentationState { .short }
}
