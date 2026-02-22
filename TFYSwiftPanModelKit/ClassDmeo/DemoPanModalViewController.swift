//
//  DemoPanModalViewController.swift
//  TFYSwiftPanModelKit
//

import UIKit

// MARK: - 基础 PanModal 弹窗

final class DemoPanModalVC: UIViewController {

    enum Mode { case short, medium, long }
    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
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
        desc.text = "支持上下拖拽切换高度\n下拉关闭弹窗\nShort ↔ Medium ↔ Long 三态切换"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel

        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, desc, btn])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
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
