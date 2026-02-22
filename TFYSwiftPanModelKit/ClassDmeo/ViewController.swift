//
//  ViewController.swift
//  TFYSwiftPanModelKit
//
//  Created by 田风有 on 2/22/26.
//

import UIKit

final class ViewController: UITableViewController {

    private let sections: [(title: String, items: [(title: String, action: Selector)])] = [
        ("PanModal - ViewController 弹窗", [
            ("基础半屏弹窗 (Short)", #selector(showBasicShort)),
            ("中等高度弹窗 (Medium)", #selector(showMedium)),
            ("全屏弹窗 (Long)", #selector(showLong)),
            ("带 ScrollView 列表弹窗", #selector(showScrollable)),
            ("自定义背景+圆角+阴影", #selector(showCustomStyle)),
        ]),
        ("PanModal - View 弹窗 (无需 VC)", [
            ("View 弹窗展示", #selector(showContentView)),
        ]),
        ("PopupView - 居中弹窗动画", [
            ("FadeInOut 渐变", #selector(popFade)),
            ("ZoomInOut 缩放", #selector(popZoom)),
            ("Spring 弹簧", #selector(popSpring)),
            ("Bounce 弹跳", #selector(popBounce)),
            ("3D Flip 翻转", #selector(pop3DFlip)),
            ("Rotate 旋转", #selector(popRotate)),
        ]),
        ("PopupView - 方向滑入弹窗", [
            ("从底部滑入", #selector(slideBottom)),
            ("从顶部滑入", #selector(slideTop)),
            ("从左侧滑入", #selector(slideLeft)),
            ("从右侧滑入", #selector(slideRight)),
        ]),
        ("PopupView - 底部面板 (BottomSheet)", [
            ("BottomSheet (可拖拽)", #selector(showBottomSheet)),
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TFYSwiftPanModelKit"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].items.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section].items[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        perform(sections[indexPath.section].items[indexPath.row].action)
    }

    // MARK: - PanModal VC
    @objc private func showBasicShort() { presentPanModal(DemoPanModalVC(mode: .short)) }
    @objc private func showMedium() { presentPanModal(DemoPanModalVC(mode: .medium)) }
    @objc private func showLong() { presentPanModal(DemoPanModalVC(mode: .long)) }
    @objc private func showScrollable() { presentPanModal(DemoScrollableVC()) }
    @objc private func showCustomStyle() { presentPanModal(DemoCustomStyleVC()) }

    // MARK: - PanModal ContentView
    @objc private func showContentView() {
        let cv = TFYSwiftPanModalContentView(frame: .zero)
        cv.backgroundColor = .systemBackground
        let label = UILabel()
        label.text = "View 弹窗\n无需 ViewController\n支持拖拽手势"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
            label.topAnchor.constraint(equalTo: cv.topAnchor, constant: 40),
        ])
        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        cv.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
            btn.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
        ])
        btn.addAction(UIAction { _ in cv.dismiss(animated: true, completion: nil) }, for: .touchUpInside)
        cv.present(in: view.window)
    }

    // MARK: - PopupView 居中动画
    @objc private func popFade() { showCenterPopup(TFYSwiftPopupFadeInOutAnimator()) }
    @objc private func popZoom() { showCenterPopup(TFYSwiftPopupZoomInOutAnimator()) }
    @objc private func popSpring() { showCenterPopup(TFYSwiftPopupSpringAnimator()) }
    @objc private func popBounce() { showCenterPopup(TFYSwiftPopupBounceAnimator()) }
    @objc private func pop3DFlip() { showCenterPopup(TFYSwiftPopup3DFlipAnimator()) }
    @objc private func popRotate() { showCenterPopup(TFYSwiftPopupRotateAnimator()) }

    // MARK: - PopupView 方向滑入
    @objc private func slideBottom() { showSlidePopup(.fromBottom) }
    @objc private func slideTop() { showSlidePopup(.fromTop) }
    @objc private func slideLeft() { showSlidePopup(.fromLeft) }
    @objc private func slideRight() { showSlidePopup(.fromRight) }

    // MARK: - BottomSheet
    @objc private func showBottomSheet() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupBottomSheetConfiguration()
        config.defaultHeight = 350
        config.enableGestures = true
        config.cornerRadius = 16
        config.allowsFullScreen = true
        let animator = TFYSwiftPopupBottomSheetAnimator(configuration: config)
        let popup = makeBottomSheetContent()
        popup.show(in: window, animator: animator, animated: true)
    }

    // MARK: - Helpers
    private func showCenterPopup(_ animator: TFYSwiftPopupBaseAnimator) {
        guard let window = view.window else { return }
        let center = TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 220)
        animator.layout = TFYSwiftPopupAnimatorLayout.center(center)
        let popup = makeCenterPopupContent()
        popup.show(in: window, animator: animator, animated: true)
    }

    private func showSlidePopup(_ direction: TFYPopupSlideDirection) {
        guard let window = view.window else { return }
        let layoutConfig: TFYSwiftPopupAnimatorLayout
        switch direction {
        case .fromBottom:
            let bottom = TFYSwiftPopupAnimatorLayoutBottom.layout(bottomMargin: 0, offsetX: 0, height: 250)
            layoutConfig = TFYSwiftPopupAnimatorLayout.bottom(bottom)
        case .fromTop:
            let top = TFYSwiftPopupAnimatorLayoutTop.layout(topMargin: 0, offsetX: 0, height: 250)
            layoutConfig = TFYSwiftPopupAnimatorLayout.top(top)
        case .fromLeft:
            let leading = TFYSwiftPopupAnimatorLayoutLeading.layout(leadingMargin: 0, offsetY: 0, width: 280)
            layoutConfig = TFYSwiftPopupAnimatorLayout.leading(leading)
        case .fromRight:
            let trailing = TFYSwiftPopupAnimatorLayoutTrailing.layout(trailingMargin: 0, offsetY: 0, width: 280)
            layoutConfig = TFYSwiftPopupAnimatorLayout.trailing(trailing)
        }
        let animator = TFYSwiftPopupSlideAnimator(direction: direction, layout: layoutConfig)
        let popup = makeSlidePopupContent(direction)
        popup.show(in: window, animator: animator, animated: true)
    }

    private func makeCenterPopupContent() -> TFYSwiftPopupView {
        let popup = TFYSwiftPopupView(frame: CGRect(x: 0, y: 0, width: 300, height: 220))
        popup.backgroundColor = .systemBackground
        popup.layer.cornerRadius = 16
        popup.layer.shadowColor = UIColor.black.cgColor
        popup.layer.shadowOpacity = 0.15
        popup.layer.shadowRadius = 20

        let icon = UILabel()
        icon.text = "✨"
        icon.font = .systemFont(ofSize: 44)
        icon.textAlignment = .center

        let title = UILabel()
        title.text = "PopupView 弹窗"
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center

        let btn = UIButton(type: .system)
        btn.setTitle("关 闭", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8

        let stack = UIStackView(arrangedSubviews: [icon, title, btn])
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: popup.centerYAnchor),
            btn.widthAnchor.constraint(equalToConstant: 160),
            btn.heightAnchor.constraint(equalToConstant: 40),
        ])
        btn.addAction(UIAction { [weak popup] _ in popup?.dismissAnimated(true) }, for: .touchUpInside)
        return popup
    }

    private func makeSlidePopupContent(_ direction: TFYPopupSlideDirection) -> TFYSwiftPopupView {
        let popup = TFYSwiftPopupView(frame: .zero)
        popup.backgroundColor = .systemBackground
        let dirText: String
        switch direction {
        case .fromBottom: dirText = "从底部滑入"
        case .fromTop: dirText = "从顶部滑入"
        case .fromLeft: dirText = "从左侧滑入"
        case .fromRight: dirText = "从右侧滑入"
        }
        let label = UILabel()
        label.text = "\(dirText)\n\n点击背景或按钮关闭"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(label)

        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(btn)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: popup.centerYAnchor, constant: -20),
            btn.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            btn.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
        ])
        btn.addAction(UIAction { [weak popup] _ in popup?.dismissAnimated(true) }, for: .touchUpInside)
        return popup
    }

    private func makeBottomSheetContent() -> TFYSwiftPopupView {
        let popup = TFYSwiftPopupView(frame: .zero)
        popup.backgroundColor = .systemBackground

        let handle = UIView()
        handle.backgroundColor = .systemGray3
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(handle)

        let title = UILabel()
        title.text = "BottomSheet 面板"
        title.font = .boldSystemFont(ofSize: 18)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(title)

        let desc = UILabel()
        desc.text = "上下拖拽切换高度\n快速下滑关闭"
        desc.numberOfLines = 0
        desc.textAlignment = .center
        desc.textColor = .secondaryLabel
        desc.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(desc)

        let btn = UIButton(type: .system)
        btn.setTitle("关闭面板", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(btn)

        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: popup.topAnchor, constant: 8),
            handle.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 40),
            handle.heightAnchor.constraint(equalToConstant: 5),
            title.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 20),
            title.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            desc.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
            desc.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            btn.topAnchor.constraint(equalTo: desc.bottomAnchor, constant: 24),
            btn.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
        ])
        btn.addAction(UIAction { [weak popup] _ in popup?.dismissAnimated(true) }, for: .touchUpInside)
        return popup
    }
}
