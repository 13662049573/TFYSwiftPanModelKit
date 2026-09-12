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
        title.font = .preferredFont(forTextStyle: .title3)
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
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
        header.font = .preferredFont(forTextStyle: .title3)
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
        title.font = .preferredFont(forTextStyle: .title2)
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
        TFYSwiftBackgroundConfig.config(behavior: .customBlurEffect)
            .backgroundAlpha(0.5)
            .backgroundBlurRadius(10)
    }

    override func contentShadow() -> TFYSwiftPanModalShadow {
        TFYSwiftPanModalShadow.none
            .shadowColor(.black.withAlphaComponent(0.3))
            .shadowRadius(12)
            .shadowOffset(CGSize(width: 0, height: -4))
            .shadowOpacity(0.4)
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
        title.font = .preferredFont(forTextStyle: .title3)
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
        title.font = .preferredFont(forTextStyle: .title3)
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

// MARK: - Pure UIView customization

final class DemoCustomPanModalContentView: TFYSwiftPanModalContentView {
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    private func configureView() {
        backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "可继承的纯 UIView PanModal"
        title.font = .preferredFont(forTextStyle: .title3)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center

        let detail = UILabel()
        detail.text = "无需 UIViewController，也可覆写高度、背景、圆角与生命周期。"
        detail.font = .preferredFont(forTextStyle: .body)
        detail.adjustsFontForContentSizeCategory = true
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 0
        detail.textAlignment = .center

        statusLabel.text = "当前状态：Short"
        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .systemIndigo
        statusLabel.textAlignment = .center

        let expand = UIButton(type: .system)
        expand.setTitle("切换到 Long", for: .normal)
        expand.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        expand.addAction(UIAction { [weak self] _ in self?.panModalTransition(to: .long) }, for: .touchUpInside)

        let close = UIButton(type: .system)
        close.setTitle("关闭", for: .normal)
        close.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true, completion: nil) }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, detail, statusLabel, expand, close])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 36),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
        ])
    }

    override func shortFormHeight() -> PanModalHeight { .init(type: .content, height: 280) }
    override func mediumFormHeight() -> PanModalHeight { .init(type: .content, height: 420) }
    override func longFormHeight() -> PanModalHeight { .init(type: .content, height: 600) }
    override func originPresentationState() -> PresentationState { .short }
    override func cornerRadius() -> CGFloat { 24 }
    override func backgroundConfig() -> TFYSwiftBackgroundConfig {
        .config(behavior: .systemVisualEffect).backgroundAlpha(0.55)
    }

    override func didChangeTransition(to state: PresentationState) {
        statusLabel.text = "当前状态：\(state.demoName)"
    }
}

// MARK: - Override hooks and custom indicator

final class DemoPanModalLifecycleVC: UIViewController {
    private let statusLabel = UILabel()
    private var eventCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "生命周期与自定义指示器"
        title.font = .preferredFont(forTextStyle: .title3)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center

        statusLabel.text = "等待回调…"
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center

        let close = UIButton(type: .system)
        close.setTitle("关闭并验证 Dismiss 回调", for: .normal)
        close.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, statusLabel, close])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    override func shortFormHeight() -> PanModalHeight { .init(type: .content, height: 300) }
    override func mediumFormHeight() -> PanModalHeight { .init(type: .content, height: 440) }
    override func longFormHeight() -> PanModalHeight { .init(type: .content, height: 580) }
    override func customIndicatorView() -> (UIView & TFYSwiftPanModalIndicatorProtocol)? {
        let indicator = DemoPanModalIndicatorView()
        indicator.onIncrement = { [weak self] in self?.panModalTransition(to: .long) }
        indicator.onDecrement = { [weak self] in self?.panModalTransition(to: .short) }
        return indicator
    }

    override func panModalTransitionWillBegin() { record("panModalTransitionWillBegin") }
    override func panModalTransitionDidFinish() { record("panModalTransitionDidFinish") }
    override func didChangeTransition(to state: PresentationState) { record("didChange → \(state.demoName)") }
    override func panModalWillDismiss() { record("panModalWillDismiss") }

    private func record(_ event: String) {
        eventCount += 1
        statusLabel.text = "回调 #\(eventCount)\n\(event)"
        statusLabel.accessibilityLabel = "第 \(eventCount) 个回调，\(event)"
    }
}

private final class DemoPanModalIndicatorView: UIView, TFYSwiftPanModalIndicatorProtocol {
    private let label = UILabel()
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?

    func didChange(to state: TFYIndicatorState) {
        label.text = state == .pullDown ? "松手可下拉" : "上下拖动"
        backgroundColor = state == .pullDown ? .systemOrange : .systemIndigo
    }

    func indicatorSize() -> CGSize { CGSize(width: 104, height: 28) }

    func setupSubviews() {
        layer.cornerRadius = 14
        backgroundColor = .systemIndigo
        label.text = "上下拖动"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textAlignment = .center
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
        isAccessibilityElement = true
        accessibilityLabel = "自定义拖拽指示器"
        accessibilityHint = "上下拖动可改变面板高度"
        accessibilityTraits = .adjustable
    }

    override func accessibilityIncrement() {
        onIncrement?()
    }

    override func accessibilityDecrement() {
        onDecrement?()
    }
}
