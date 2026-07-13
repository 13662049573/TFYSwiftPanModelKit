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
            ("边缘滑动关闭", #selector(showEdgeInteractive)),
            ("防频繁点击 (快速连点)", #selector(showFrequentTap)),
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
        ("presentPopup - 控制器居中动画", [
            ("Fade 弹出控制器", #selector(showPopupVCFade)),
            ("Zoom 弹出控制器", #selector(showPopupVCZoom)),
            ("Spring 弹出控制器", #selector(showPopupVCSpring)),
            ("Bounce 弹出控制器", #selector(showPopupVCBounce)),
            ("3D Flip 弹出控制器", #selector(showPopupVCFlip)),
            ("Rotate 弹出控制器", #selector(showPopupVCRotate)),
        ]),
        ("presentPopup - 控制器方向滑入", [
            ("从底部滑入控制器", #selector(showPopupVCSlideBottom)),
            ("从顶部滑入控制器", #selector(showPopupVCSlideTop)),
            ("从左侧滑入控制器", #selector(showPopupVCSlideLeft)),
            ("从右侧滑入控制器", #selector(showPopupVCSlideRight)),
        ]),
        ("presentPopup - 控制器高级能力", [
            ("自定义配置控制器 (模糊+Bounce)", #selector(showPopupVCConfigured)),
            ("不可关闭控制器 (代码关闭)", #selector(showPopupVCNonDismissible)),
            ("拖拽/滑动关闭控制器", #selector(showPopupVCDragSwipe)),
            ("键盘避让 transform", #selector(showPopupVCKeyboardTransform)),
            ("键盘避让 constraint", #selector(showPopupVCKeyboardConstraint)),
            ("键盘避让 resize", #selector(showPopupVCKeyboardResize)),
            ("穿透背景控制器", #selector(showPopupVCPenetrable)),
            ("自动关闭控制器 (2s)", #selector(showPopupVCAutoDismiss)),
            ("无障碍控制器弹窗", #selector(showPopupVCAccessibility)),
        ]),
        ("PopupView - 高级功能", [
            ("配置化弹窗 (模糊背景)", #selector(showConfiguredPopup)),
            ("优先级队列弹窗", #selector(showPriorityPopup)),
            ("优先级替换 (High→Urgent)", #selector(showPriorityReplace)),
            ("优先级 Overlay 叠加", #selector(showPriorityOverlay)),
            ("不可关闭弹窗 (代码关闭)", #selector(showNonDismissiblePopup)),
            ("拖拽/滑动关闭弹窗", #selector(showDragSwipeDismissPopup)),
            ("暗色模式跟随验证", #selector(showDarkModePopup)),
            ("方向动画 (Upward)", #selector(showUpwardPopup)),
        ]),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TFYSwiftPanModelKit"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        navigationController?.navigationBar.prefersLargeTitles = true
        // 防止历史会话中卡住的优先级队列影响新演示
        TFYSwiftPopupPriorityManager.shared.clearAllQueues()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].items.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section].title }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = sections[indexPath.section].items[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.numberOfLines = 2
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
    @objc private func showEdgeInteractive() { presentPanModal(DemoEdgeInteractiveVC()) }
    @objc private func showFrequentTap() { presentPanModal(DemoFrequentTapVC()) }

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

    // MARK: - presentPopup 控制器居中
    @objc private func showPopupVCFade() { presentPopup(DemoPopupContentVC(style: .fade)) }
    @objc private func showPopupVCZoom() { presentPopup(DemoPopupContentVC(style: .zoom)) }
    @objc private func showPopupVCSpring() { presentPopup(DemoPopupContentVC(style: .spring)) }
    @objc private func showPopupVCBounce() { presentPopup(DemoPopupContentVC(style: .bounce)) }
    @objc private func showPopupVCFlip() { presentPopup(DemoPopupContentVC(style: .flip)) }
    @objc private func showPopupVCRotate() { presentPopup(DemoPopupContentVC(style: .rotate)) }

    // MARK: - presentPopup 控制器方向
    @objc private func showPopupVCSlideBottom() { presentPopup(DemoPopupContentVC(style: .slideBottom)) }
    @objc private func showPopupVCSlideTop() { presentPopup(DemoPopupContentVC(style: .slideTop)) }
    @objc private func showPopupVCSlideLeft() { presentPopup(DemoPopupContentVC(style: .slideLeft)) }
    @objc private func showPopupVCSlideRight() { presentPopup(DemoPopupContentVC(style: .slideRight)) }

    // MARK: - presentPopup 控制器高级
    @objc private func showPopupVCConfigured() { presentPopup(DemoConfiguredPopupContentVC()) }
    @objc private func showPopupVCNonDismissible() { presentPopup(DemoNonDismissiblePopupVC()) }
    @objc private func showPopupVCDragSwipe() { presentPopup(DemoDragSwipePopupVC()) }
    @objc private func showPopupVCKeyboardTransform() { presentPopup(DemoKeyboardPopupVC(mode: .transform)) }
    @objc private func showPopupVCKeyboardConstraint() { presentPopup(DemoKeyboardPopupVC(mode: .constraint)) }
    @objc private func showPopupVCKeyboardResize() { presentPopup(DemoKeyboardPopupVC(mode: .resize)) }
    @objc private func showPopupVCPenetrable() { presentPopup(DemoPenetrablePopupVC()) }
    @objc private func showPopupVCAutoDismiss() { presentPopup(DemoAutoDismissPopupVC()) }
    @objc private func showPopupVCAccessibility() { presentPopup(DemoAccessibilityPopupVC()) }

    // MARK: - PopupView 高级功能
    @objc private func showConfiguredPopup() {
        let config = TFYSwiftPopupViewConfiguration()
        config.backgroundStyle = .blur
        config.blurStyle = .systemMaterialDark
        config.cornerRadius = 20
        config.enableHapticFeedback = true
        config.dismissOnBackgroundTap = true

        let animator = TFYSwiftPopupSpringAnimator()
        let center = TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 220)
        animator.layout = TFYSwiftPopupAnimatorLayout.center(center)

        let popup = makeCenterPopupContent()
        popup.show(in: view.window, animator: animator, configuration: config, animated: true)
    }

    @objc private func showPriorityPopup() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupViewConfiguration()
        config.enablePriorityManagement = true
        config.priority = .high
        config.priorityStrategy = .queue
        config.enableHapticFeedback = true

        let animator = TFYSwiftPopupFadeInOutAnimator()
        let center = TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 280, height: 180)
        animator.layout = TFYSwiftPopupAnimatorLayout.center(center)

        let popup = makeLabeledPopup(size: CGSize(width: 280, height: 180), text: "高优先级弹窗\n(队列管理)")
        popup.show(in: window, animator: animator, configuration: config, animated: true)
    }

    @objc private func showPriorityReplace() {
        guard let window = view.window else { return }

        let lowConfig = TFYSwiftPopupViewConfiguration()
        lowConfig.enablePriorityManagement = true
        lowConfig.priority = .low
        lowConfig.priorityStrategy = .queue
        lowConfig.canBeReplacedByHigherPriority = true
        lowConfig.dismissOnBackgroundTap = false

        let lowAnimator = TFYSwiftPopupFadeInOutAnimator()
        lowAnimator.layout = TFYSwiftPopupAnimatorLayout.center(
            TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 280, height: 160)
        )
        let lowPopup = makeLabeledPopup(size: CGSize(width: 280, height: 160), text: "低优先级\n将被替换")
        lowPopup.show(in: window, animator: lowAnimator, configuration: lowConfig, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let highConfig = TFYSwiftPopupViewConfiguration()
            highConfig.enablePriorityManagement = true
            highConfig.priority = .urgent
            highConfig.priorityStrategy = .queue
            highConfig.canBeReplacedByHigherPriority = true

            let highAnimator = TFYSwiftPopupSpringAnimator()
            highAnimator.layout = TFYSwiftPopupAnimatorLayout.center(
                TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 180)
            )
            let highPopup = self.makeLabeledPopup(size: CGSize(width: 300, height: 180), text: "Urgent 优先级\n已替换低优先级")
            highPopup.show(in: window, animator: highAnimator, configuration: highConfig, animated: true)
        }
    }

    @objc private func showPriorityOverlay() {
        guard let window = view.window else { return }

        let baseConfig = TFYSwiftPopupViewConfiguration()
        baseConfig.enablePriorityManagement = true
        baseConfig.priority = .normal
        baseConfig.priorityStrategy = .overlay
        baseConfig.dismissOnBackgroundTap = false

        let baseAnimator = TFYSwiftPopupFadeInOutAnimator()
        baseAnimator.layout = TFYSwiftPopupAnimatorLayout.center(
            TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: -40, offsetX: 0, width: 280, height: 160)
        )
        let basePopup = makeLabeledPopup(size: CGSize(width: 280, height: 160), text: "底层 Normal\n(Overlay 策略)")
        basePopup.show(in: window, animator: baseAnimator, configuration: baseConfig, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let topConfig = TFYSwiftPopupViewConfiguration()
            topConfig.enablePriorityManagement = true
            topConfig.priority = .high
            topConfig.priorityStrategy = .overlay

            let topAnimator = TFYSwiftPopupSpringAnimator()
            topAnimator.layout = TFYSwiftPopupAnimatorLayout.center(
                TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 60, offsetX: 0, width: 260, height: 150)
            )
            let topPopup = self.makeLabeledPopup(size: CGSize(width: 260, height: 150), text: "上层 High\n叠加显示")
            topPopup.show(in: window, animator: topAnimator, configuration: topConfig, animated: true)
        }
    }

    @objc private func showNonDismissiblePopup() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupViewConfiguration()
        config.isDismissible = false
        config.dismissOnBackgroundTap = false
        config.enableDragToDismiss = false
        config.enableSwipeToDismiss = false
        config.cornerRadius = 16

        let animator = TFYSwiftPopupZoomInOutAnimator()
        animator.layout = TFYSwiftPopupAnimatorLayout.center(
            TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 220)
        )

        let popup = makeLabeledPopup(size: CGSize(width: 300, height: 220), text: "不可手势关闭\n点击按钮以代码关闭")
        popup.show(in: window, animator: animator, configuration: config, animated: true)
    }

    @objc private func showDragSwipeDismissPopup() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupViewConfiguration()
        config.enableDragToDismiss = true
        config.enableSwipeToDismiss = true
        config.dragDismissThreshold = 0.25
        config.cornerRadius = 16
        config.backgroundStyle = .solidColor

        let animator = TFYSwiftPopupBounceAnimator()
        animator.layout = TFYSwiftPopupAnimatorLayout.center(
            TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 200)
        )
        let popup = makeLabeledPopup(size: CGSize(width: 300, height: 200), text: "向下拖拽或左右滑动关闭")
        popup.show(in: window, animator: animator, configuration: config, animated: true)
    }

    @objc private func showDarkModePopup() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupViewConfiguration()
        config.theme = .default
        config.backgroundStyle = .blur
        config.cornerRadius = 16
        config.enableAccessibility = true

        let animator = TFYSwiftPopupSpringAnimator()
        animator.layout = TFYSwiftPopupAnimatorLayout.center(
            TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 240)
        )

        let popup = TFYSwiftPopupView(frame: CGRect(x: 0, y: 0, width: 300, height: 240))
        popup.backgroundColor = .systemBackground
        popup.layer.cornerRadius = 16

        let label = UILabel()
        label.text = "主题跟随系统\n切换外观后 blur/背景会刷新"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(label)

        let toggle = UIButton(type: .system)
        toggle.setTitle("切换界面外观", for: .normal)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(toggle)

        let close = UIButton(type: .system)
        close.setTitle("关闭", for: .normal)
        close.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(close)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            label.topAnchor.constraint(equalTo: popup.topAnchor, constant: 36),
            toggle.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            toggle.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            close.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            close.topAnchor.constraint(equalTo: toggle.bottomAnchor, constant: 12),
        ])

        toggle.addAction(UIAction { [weak self] _ in
            guard let window = self?.view.window else { return }
            let next: UIUserInterfaceStyle = window.overrideUserInterfaceStyle == .dark ? .light : .dark
            window.overrideUserInterfaceStyle = next
        }, for: .touchUpInside)
        close.addAction(UIAction { [weak popup] _ in popup?.dismissAnimated(true) }, for: .touchUpInside)

        popup.show(in: window, animator: animator, configuration: config, animated: true)
    }

    @objc private func showUpwardPopup() {
        guard let window = view.window else { return }
        let upward = TFYSwiftPopupAnimatorLayoutBottom.layout(bottomMargin: 40, offsetX: 0, height: 200)
        let animator = TFYSwiftPopupUpwardAnimator()
        animator.layout = TFYSwiftPopupAnimatorLayout.bottom(upward)
        let popup = makeSlidePopupContent(.fromBottom)
        popup.show(in: window, animator: animator, animated: true)
    }

    // MARK: - Helpers
    private func makeLabeledPopup(size: CGSize, text: String) -> TFYSwiftPopupView {
        let popup = TFYSwiftPopupView(frame: CGRect(origin: .zero, size: size))
        popup.backgroundColor = .systemBackground
        popup.layer.cornerRadius = 16
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(label)
        let btn = UIButton(type: .system)
        btn.setTitle("关闭", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(btn)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: popup.centerYAnchor, constant: -16),
            btn.centerXAnchor.constraint(equalTo: popup.centerXAnchor),
            btn.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
        ])
        btn.addAction(UIAction { [weak popup] _ in popup?.dismissAnimated(true) }, for: .touchUpInside)
        return popup
    }

    private func showCenterPopup(_ animator: TFYSwiftPopupBaseAnimator) {
        guard let window = view.window else { return }
        let center = TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 220)
        animator.layout = TFYSwiftPopupAnimatorLayout.center(center)
        let popup = makeCenterPopupContent()
        let config = TFYSwiftPopupViewConfiguration()
        config.enablePriorityManagement = false
        popup.show(in: window, animator: animator, configuration: config, animated: true)
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
        let config = TFYSwiftPopupViewConfiguration()
        config.enablePriorityManagement = false
        popup.show(in: window, animator: animator, configuration: config, animated: true)
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
