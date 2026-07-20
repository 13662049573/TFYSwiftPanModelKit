//
//  ViewController.swift
//  TFYSwiftPanModelKit
//
//  Created by 田风有 on 2/22/26.
//

import UIKit

final class ViewController: UITableViewController, UISearchResultsUpdating, TFYSwiftPopupViewDelegate {

    private struct DemoItem {
        let title: String
        let detail: String
        let symbol: String
        let action: Selector
    }

    private struct DemoSection {
        let title: String
        let items: [DemoItem]
    }

    private lazy var allSections: [DemoSection] = [
        DemoSection(title: "PanModal · 状态与滚动", items: [
            DemoItem(title: "Short 半屏", detail: "250pt 内容高度，拖拽与背景关闭", symbol: "rectangle.bottomhalf.inset.filled", action: #selector(showBasicShort)),
            DemoItem(title: "Medium 中屏", detail: "400pt 初始高度，支持三态切换", symbol: "rectangle.split.2x1", action: #selector(showMedium)),
            DemoItem(title: "Long 全屏", detail: "Short / Medium / Long 按钮与状态回调", symbol: "rectangle.inset.filled", action: #selector(showLong)),
            DemoItem(title: "ScrollView 联动", detail: "列表滚动与面板拖拽手势协调", symbol: "list.bullet.rectangle", action: #selector(showScrollable)),
            DemoItem(title: "纯 UIView PanModal", detail: "无需 UIViewController 的展示与关闭", symbol: "square.on.square", action: #selector(showContentView)),
        ]),
        DemoSection(title: "PanModal · 交互与视觉", items: [
            DemoItem(title: "自定义背景、圆角与阴影", detail: "Blur、20pt 圆角和内容阴影", symbol: "wand.and.stars", action: #selector(showCustomStyle)),
            DemoItem(title: "PageSheet 父页面动画", detail: "presentingVCAnimationStyle = pageSheet", symbol: "rectangle.stack", action: #selector(showPageSheetStyle)),
            DemoItem(title: "ShoppingCart 父页面动画", detail: "展示父控制器缩放转场", symbol: "cart", action: #selector(showShoppingCartStyle)),
            DemoItem(title: "禁止手势与背景关闭", detail: "仍可通过按钮安全地代码关闭", symbol: "lock", action: #selector(showLockedPanModal)),
            DemoItem(title: "键盘自动避让", detail: "输入框、键盘偏移与面板布局更新", symbol: "keyboard", action: #selector(showPanModalKeyboard)),
            DemoItem(title: "屏幕边缘交互关闭", detail: "从左边缘向右滑动关闭", symbol: "arrow.right.to.line", action: #selector(showEdgeInteractive)),
            DemoItem(title: "防频繁点击", detail: "快速重复触发、提示和触觉反馈", symbol: "hand.raised", action: #selector(showFrequentTap)),
        ]),
        DemoSection(title: "PopupView · 居中动画", items: [
            DemoItem(title: "FadeInOut", detail: "透明度渐入渐出", symbol: "circle.lefthalf.filled", action: #selector(popFade)),
            DemoItem(title: "ZoomInOut", detail: "中心缩放", symbol: "arrow.up.left.and.arrow.down.right", action: #selector(popZoom)),
            DemoItem(title: "Spring", detail: "阻尼弹簧动画", symbol: "waveform.path", action: #selector(popSpring)),
            DemoItem(title: "Bounce", detail: "弹跳入场和离场", symbol: "circle.grid.cross", action: #selector(popBounce)),
            DemoItem(title: "3D Flip", detail: "三维翻转动画", symbol: "view.3d", action: #selector(pop3DFlip)),
            DemoItem(title: "Rotate", detail: "旋转缩放动画", symbol: "arrow.clockwise", action: #selector(popRotate)),
        ]),
        DemoSection(title: "PopupView · 方向与滑入", items: [
            DemoItem(title: "Slide 从底部", detail: "Bottom 布局与 fromBottom 动画", symbol: "arrow.up", action: #selector(slideBottom)),
            DemoItem(title: "Slide 从顶部", detail: "Top 布局与 fromTop 动画", symbol: "arrow.down", action: #selector(slideTop)),
            DemoItem(title: "Slide 从左侧", detail: "Leading 布局与 fromLeft 动画", symbol: "arrow.right", action: #selector(slideLeft)),
            DemoItem(title: "Slide 从右侧", detail: "Trailing 布局与 fromRight 动画", symbol: "arrow.left", action: #selector(slideRight)),
            DemoItem(title: "Directional Upward", detail: "TFYSwiftPopupUpwardAnimator", symbol: "arrow.up.circle", action: #selector(showUpwardPopup)),
            DemoItem(title: "Directional Downward", detail: "TFYSwiftPopupDownwardAnimator", symbol: "arrow.down.circle", action: #selector(showDownwardPopup)),
            DemoItem(title: "Directional Leftward", detail: "TFYSwiftPopupLeftwardAnimator", symbol: "arrow.left.circle", action: #selector(showLeftwardPopup)),
            DemoItem(title: "Directional Rightward", detail: "TFYSwiftPopupRightwardAnimator", symbol: "arrow.right.circle", action: #selector(showRightwardPopup)),
        ]),
        DemoSection(title: "PopupView · BottomSheet", items: [
            DemoItem(title: "BottomSheet 基础拖拽", detail: "自动容器高度、吸附和下滑关闭", symbol: "rectangle.bottomthird.inset.filled", action: #selector(showBottomSheet)),
            DemoItem(title: "BottomSheet 嵌套滚动", detail: "内部 ScrollView 与面板手势优先级", symbol: "scroll", action: #selector(showScrollableBottomSheet)),
        ]),
        DemoSection(title: "presentPopup · 控制器动画", items: [
            DemoItem(title: "VC Fade", detail: "UIViewController 渐变弹出", symbol: "circle.lefthalf.filled", action: #selector(showPopupVCFade)),
            DemoItem(title: "VC Zoom", detail: "UIViewController 缩放弹出", symbol: "arrow.up.left.and.arrow.down.right", action: #selector(showPopupVCZoom)),
            DemoItem(title: "VC Spring", detail: "UIViewController 弹簧弹出", symbol: "waveform.path", action: #selector(showPopupVCSpring)),
            DemoItem(title: "VC Bounce", detail: "UIViewController 弹跳弹出", symbol: "circle.grid.cross", action: #selector(showPopupVCBounce)),
            DemoItem(title: "VC 3D Flip", detail: "UIViewController 三维翻转", symbol: "view.3d", action: #selector(showPopupVCFlip)),
            DemoItem(title: "VC Rotate", detail: "UIViewController 旋转弹出", symbol: "arrow.clockwise", action: #selector(showPopupVCRotate)),
            DemoItem(title: "VC 从底部滑入", detail: "控制器 Bottom 布局", symbol: "arrow.up", action: #selector(showPopupVCSlideBottom)),
            DemoItem(title: "VC 从顶部滑入", detail: "控制器 Top 布局", symbol: "arrow.down", action: #selector(showPopupVCSlideTop)),
            DemoItem(title: "VC 从左侧滑入", detail: "控制器 Leading 布局", symbol: "arrow.right", action: #selector(showPopupVCSlideLeft)),
            DemoItem(title: "VC 从右侧滑入", detail: "控制器 Trailing 布局", symbol: "arrow.left", action: #selector(showPopupVCSlideRight)),
        ]),
        DemoSection(title: "presentPopup · 完整能力", items: [
            DemoItem(title: "模糊背景 + Bounce", detail: "preferredPopupConfiguration / Animator", symbol: "aqi.medium", action: #selector(showPopupVCConfigured)),
            DemoItem(title: "不可手势关闭", detail: "isDismissible = false，按钮代码关闭", symbol: "lock", action: #selector(showPopupVCNonDismissible)),
            DemoItem(title: "拖拽与滑动关闭", detail: "dragDismissThreshold 与 Swipe", symbol: "hand.draw", action: #selector(showPopupVCDragSwipe)),
            DemoItem(title: "键盘避让 · Transform", detail: "整体变换避让键盘", symbol: "keyboard", action: #selector(showPopupVCKeyboardTransform)),
            DemoItem(title: "键盘避让 · Constraint", detail: "约束偏移避让键盘", symbol: "keyboard", action: #selector(showPopupVCKeyboardConstraint)),
            DemoItem(title: "键盘避让 · Resize", detail: "调整可用区域避让键盘", symbol: "keyboard", action: #selector(showPopupVCKeyboardResize)),
            DemoItem(title: "背景触摸穿透", detail: "isPenetrable = true", symbol: "square.dashed", action: #selector(showPopupVCPenetrable)),
            DemoItem(title: "2 秒自动关闭", detail: "autoDismissDelay 生命周期", symbol: "timer", action: #selector(showPopupVCAutoDismiss)),
            DemoItem(title: "VoiceOver 无障碍", detail: "焦点、标签与关闭按钮", symbol: "accessibility", action: #selector(showPopupVCAccessibility)),
        ]),
        DemoSection(title: "PopupView · 配置、容器与生命周期", items: [
            DemoItem(title: "模糊背景配置", detail: "Blur、圆角、触觉和背景点击", symbol: "aqi.medium", action: #selector(showConfiguredPopup)),
            DemoItem(title: "渐变背景", detail: "backgroundStyle = gradient", symbol: "square.fill.on.square.fill", action: #selector(showGradientPopup)),
            DemoItem(title: "容器外观", detail: "内容边距、圆角、阴影和自定义主题", symbol: "square.resize", action: #selector(showContainerAppearancePopup)),
            DemoItem(title: "Smart 容器自动发现", detail: "nil 容器、自动发现与回退", symbol: "scope", action: #selector(showAutoDiscoveredPopup)),
            DemoItem(title: "生命周期 Delegate", detail: "Will/Did Appear 与 Dismiss 回调", symbol: "point.3.connected.trianglepath.dotted", action: #selector(showLifecyclePopup)),
            DemoItem(title: "暗色模式动态刷新", detail: "Theme 与 Blur 随 Trait 更新", symbol: "circle.righthalf.filled", action: #selector(showDarkModePopup)),
            DemoItem(title: "纯 View 不可关闭", detail: "直接使用 TFYSwiftPopupView", symbol: "lock.square", action: #selector(showNonDismissiblePopup)),
            DemoItem(title: "纯 View 拖拽关闭", detail: "直接验证拖动和横向滑动", symbol: "hand.draw", action: #selector(showDragSwipeDismissPopup)),
        ]),
        DemoSection(title: "PopupView · 优先级策略", items: [
            DemoItem(title: "Queue 同级 FIFO", detail: "相同优先级严格按 1 → 2 → 3 展示", symbol: "list.number", action: #selector(showPriorityFIFO)),
            DemoItem(title: "Queue 优先级排序", detail: "Urgent 后入队但先于 Low 展示", symbol: "arrow.up.arrow.down", action: #selector(showPriorityOrdering)),
            DemoItem(title: "Replace 高优先级替换", detail: "Urgent 替换可被替换的 Low", symbol: "arrow.triangle.2.circlepath", action: #selector(showPriorityReplace)),
            DemoItem(title: "Overlay 叠加", detail: "Normal 与 High 同时显示", symbol: "square.stack.3d.up", action: #selector(showPriorityOverlay)),
            DemoItem(title: "Reject 拒绝策略", detail: "容量已满时拒绝第二个展示", symbol: "nosign", action: #selector(showPriorityReject)),
        ]),
    ]

    private var sections: [DemoSection] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private var didPositionCatalog = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TFYSwiftPanModelKit"
        sections = allSections
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.keyboardDismissMode = .onDrag
        tableView.tableHeaderView = makeCatalogHeader()

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索动画、交互或 API"
        searchController.searchBar.accessibilityIdentifier = "demo.search"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        // 防止历史会话中卡住的优先级队列影响新演示
        TFYSwiftPopupPriorityManager.shared.clearAllQueues()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPositionCatalog else { return }
        didPositionCatalog = true
        tableView.setContentOffset(CGPoint(x: 0, y: -tableView.adjustedContentInset.top), animated: false)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { sections[section].items.count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "\(sections[section].title) · \(sections[section].items.count)"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DemoCell")
        let item = sections[indexPath.section].items[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.detail
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.numberOfLines = 2
        content.image = UIImage(systemName: item.symbol)
        content.imageProperties.tintColor = .systemIndigo
        content.imageProperties.maximumSize = CGSize(width: 28, height: 28)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.isAccessibilityElement = true
        cell.accessibilityTraits.insert(.button)
        cell.accessibilityLabel = item.title
        cell.accessibilityHint = item.detail
        cell.accessibilityIdentifier = "demo.\(NSStringFromSelector(item.action))"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        perform(sections[indexPath.section].items[indexPath.row].action)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else {
            sections = allSections
            tableView.backgroundView = nil
            tableView.reloadData()
            return
        }
        sections = allSections.compactMap { section in
            let matches = section.items.filter {
                section.title.localizedCaseInsensitiveContains(query)
                    || $0.title.localizedCaseInsensitiveContains(query)
                    || $0.detail.localizedCaseInsensitiveContains(query)
            }
            return matches.isEmpty ? nil : DemoSection(title: section.title, items: matches)
        }
        let empty = UILabel()
        empty.text = "没有匹配的 Demo"
        empty.textColor = .secondaryLabel
        empty.textAlignment = .center
        tableView.backgroundView = sections.isEmpty ? empty : nil
        tableView.reloadData()
    }

    private func makeCatalogHeader() -> UIView {
        let count = allSections.reduce(0) { $0 + $1.items.count }
        let header = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 116))
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 18
        card.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(card)

        let title = UILabel()
        title.text = "完整能力目录"
        title.font = .preferredFont(forTextStyle: .headline)
        let detail = UILabel()
        detail.text = "\(count) 个可运行场景 · PanModal + PopupView\n点击条目即可验证真实动画、手势和生命周期"
        detail.font = .preferredFont(forTextStyle: .subheadline)
        detail.textColor = .secondaryLabel
        detail.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [title, detail])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            card.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
        header.isAccessibilityElement = true
        header.accessibilityLabel = "完整能力目录，\(count) 个可运行场景"
        return header
    }

    // MARK: - PanModal VC
    @objc private func showBasicShort() { presentPanModal(DemoPanModalVC(mode: .short)) }
    @objc private func showMedium() { presentPanModal(DemoPanModalVC(mode: .medium)) }
    @objc private func showLong() { presentPanModal(DemoPanModalVC(mode: .long)) }
    @objc private func showScrollable() { presentPanModal(DemoScrollableVC()) }
    @objc private func showCustomStyle() { presentPanModal(DemoCustomStyleVC()) }
    @objc private func showEdgeInteractive() { presentPanModal(DemoEdgeInteractiveVC()) }
    @objc private func showFrequentTap() { presentPanModal(DemoFrequentTapVC()) }
    @objc private func showPageSheetStyle() {
        presentPanModal(DemoPanModalVC(mode: .long, presentingStyle: .pageSheet))
    }
    @objc private func showShoppingCartStyle() {
        presentPanModal(DemoPanModalVC(mode: .long, presentingStyle: .shoppingCart))
    }
    @objc private func showLockedPanModal() {
        presentPanModal(DemoPanModalVC(mode: .medium, locksInteractiveDismissal: true))
    }
    @objc private func showPanModalKeyboard() { presentPanModal(DemoPanModalKeyboardVC()) }

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

    @objc private func showScrollableBottomSheet() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupBottomSheetConfiguration()
        config.defaultHeight = 420
        config.minimumHeight = 180
        config.maximumHeight = 0
        config.allowsFullScreen = true
        let popup = makeScrollableBottomSheetContent()
        popup.show(in: window, animator: TFYSwiftPopupBottomSheetAnimator(configuration: config), animated: true)
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

    @objc private func showGradientPopup() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupViewConfiguration()
        config.backgroundStyle = .gradient
        config.cornerRadius = 20
        let animator = TFYSwiftPopupZoomInOutAnimator()
        animator.layout = .center(.layout(offsetY: 0, offsetX: 0, width: 300, height: 210))
        let popup = makeLabeledPopup(size: CGSize(width: 300, height: 210), text: "Gradient 背景\n点击背景或按钮关闭")
        popup.show(in: window, animator: animator, configuration: config, animated: true)
    }

    @objc private func showContainerAppearancePopup() {
        guard let window = view.window else { return }
        let config = TFYSwiftPopupViewConfiguration()
        config.theme = .custom
        config.customThemeBackgroundColor = .secondarySystemBackground
        config.customThemeTextColor = .label
        config.customThemeCornerRadius = 24
        config.containerConfiguration.contentInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        config.containerConfiguration.shadowEnabled = true
        config.containerConfiguration.shadowOpacity = 0.28
        config.containerConfiguration.shadowRadius = 24
        config.containerConfiguration.shadowOffset = CGSize(width: 0, height: 12)
        let animator = TFYSwiftPopupSpringAnimator()
        animator.layout = .center(.layout(offsetY: 0, offsetX: 0, width: 310, height: 220))
        let popup = makeLabeledPopup(size: CGSize(width: 310, height: 220), text: "容器外观\n主题 · 圆角 · 阴影 · Insets")
        popup.show(in: window, animator: animator, configuration: config, animated: true)
    }

    @objc private func showAutoDiscoveredPopup() {
        let config = TFYSwiftPopupViewConfiguration()
        config.enableContainerAutoDiscovery = true
        config.containerSelectionStrategy = .smart
        config.preferredContainerType = .viewController
        config.allowContainerFallback = true
        config.cornerRadius = 18
        let animator = TFYSwiftPopupFadeInOutAnimator()
        animator.layout = .center(.layout(offsetY: 0, offsetX: 0, width: 310, height: 210))
        let popup = makeLabeledPopup(size: CGSize(width: 310, height: 210), text: "Smart 容器已自动选择\n调用 show(in: nil)")
        popup.show(in: nil, animator: animator, configuration: config, animated: true)
    }

    @objc private func showLifecyclePopup() {
        guard let window = view.window else { return }
        let animator = TFYSwiftPopupSpringAnimator()
        animator.layout = .center(.layout(offsetY: 0, offsetX: 0, width: 320, height: 220))
        let popup = makeLabeledPopup(size: CGSize(width: 320, height: 220), text: "Lifecycle\n准备展示…")
        popup.delegate = self
        popup.show(in: window, animator: animator, animated: true)
    }

    @objc private func showPriorityFIFO() {
        showPrioritySequence(
            [
                ("FIFO 1 / 3", .normal),
                ("FIFO 2 / 3", .normal),
                ("FIFO 3 / 3", .normal),
            ],
            expectedOrder: "1 → 2 → 3"
        )
    }

    @objc private func showPriorityOrdering() {
        showPrioritySequence(
            [
                ("当前展示", .normal),
                ("先入队的 Low", .low),
                ("后入队的 Urgent", .urgent),
            ],
            expectedOrder: "Normal → Urgent → Low"
        )
    }

    private func showPrioritySequence(
        _ items: [(title: String, priority: TFYPopupPriority)],
        expectedOrder: String
    ) {
        guard let window = view.window else { return }
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.clearAllQueues()
        manager.maxSimultaneousPopups = 1
        for item in items {
            let config = TFYSwiftPopupViewConfiguration()
            config.enablePriorityManagement = true
            config.priority = item.priority
            config.priorityStrategy = .queue
            config.autoDismissDelay = 3
            config.maxWaitingTime = 15
            let animator = TFYSwiftPopupFadeInOutAnimator()
            animator.layout = .center(.layout(offsetY: 0, offsetX: 0, width: 310, height: 210))
            let priority = TFYSwiftPopupPriorityManager.priorityDescription(item.priority)
            let popup = makeLabeledPopup(
                size: CGSize(width: 310, height: 210),
                text: "\(item.title)\n优先级：\(priority)\n期望顺序：\(expectedOrder)"
            )
            popup.show(in: window, animator: animator, configuration: config, animated: true)
        }
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
        let lowPopup = makeLabeledPopup(size: CGSize(width: 280, height: 160), text: "Low 正在展示\n0.6 秒后由 Urgent 替换")
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
            let highPopup = self.makeLabeledPopup(size: CGSize(width: 300, height: 180), text: "✅ Urgent > Low\n高优先级替换成功")
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

    @objc private func showPriorityReject() {
        guard let window = view.window else { return }
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.clearAllQueues()
        manager.maxSimultaneousPopups = 1

        let baseConfig = TFYSwiftPopupViewConfiguration()
        baseConfig.enablePriorityManagement = true
        baseConfig.priorityStrategy = .overlay
        baseConfig.dismissOnBackgroundTap = false
        baseConfig.autoDismissDelay = 2.5
        let animator = TFYSwiftPopupFadeInOutAnimator()
        animator.layout = .center(.layout(offsetY: 0, offsetX: 0, width: 300, height: 190))
        let base = makeLabeledPopup(size: CGSize(width: 300, height: 190), text: "容量已占满\n准备提交 Reject 请求…")
        base.show(in: window, animator: animator, configuration: baseConfig, animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self, weak base] in
            guard let self, let base else { return }
            let rejectedConfig = TFYSwiftPopupViewConfiguration()
            rejectedConfig.enablePriorityManagement = true
            rejectedConfig.priorityStrategy = .reject
            let rejected = self.makeLabeledPopup(size: CGSize(width: 260, height: 150), text: "不应显示")
            rejected.show(in: window, animator: TFYSwiftPopupSpringAnimator(), configuration: rejectedConfig, animated: true)
            DispatchQueue.main.async {
                self.updatePopupMessage(base, text: rejected.isShowing ? "Reject 未生效" : "✅ 第二个弹窗已被 Reject")
            }
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
        showDirectionalPopup(TFYSwiftPopupUpwardAnimator(), title: "Upward · 从下向上")
    }

    @objc private func showDownwardPopup() {
        showDirectionalPopup(TFYSwiftPopupDownwardAnimator(), title: "Downward · 从上向下")
    }

    @objc private func showLeftwardPopup() {
        showDirectionalPopup(TFYSwiftPopupLeftwardAnimator(), title: "Leftward · 从右向左")
    }

    @objc private func showRightwardPopup() {
        showDirectionalPopup(TFYSwiftPopupRightwardAnimator(), title: "Rightward · 从左向右")
    }

    private func showDirectionalPopup(_ animator: TFYSwiftPopupDirectionalAnimator, title: String) {
        guard let window = view.window else { return }
        animator.layout = .center(.layout(offsetY: 0, offsetX: 0, width: 300, height: 200))
        let popup = makeLabeledPopup(size: CGSize(width: 300, height: 200), text: title)
        popup.show(in: window, animator: animator, animated: true)
    }

    // MARK: - Helpers
    private func makeLabeledPopup(size: CGSize, text: String) -> TFYSwiftPopupView {
        let popup = TFYSwiftPopupView(frame: CGRect(origin: .zero, size: size))
        popup.backgroundColor = .systemBackground
        popup.layer.cornerRadius = 16
        let label = UILabel()
        label.text = text
        label.tag = 9_101
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

    private func updatePopupMessage(_ popup: TFYSwiftPopupView, text: String) {
        (popup.viewWithTag(9_101) as? UILabel)?.text = text
    }

    func popupViewWillAppear(_ popupView: TFYSwiftPopupView) {
        updatePopupMessage(popupView, text: "1. popupViewWillAppear")
    }

    func popupViewDidAppear(_ popupView: TFYSwiftPopupView) {
        updatePopupMessage(popupView, text: "2. popupViewDidAppear\n现在关闭以继续验证")
    }

    func popupViewWillDisappear(_ popupView: TFYSwiftPopupView) {
        updatePopupMessage(popupView, text: "3. popupViewWillDisappear")
    }

    func popupViewDidDisappear(_ popupView: TFYSwiftPopupView) {
        UIAccessibility.post(notification: .announcement, argument: "4. popupViewDidDisappear")
    }

    func popupViewShouldDismiss(_ popupView: TFYSwiftPopupView) -> Bool { true }

    func popupViewDidTapBackground(_ popupView: TFYSwiftPopupView) {
        updatePopupMessage(popupView, text: "收到背景点击回调")
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

    private func makeScrollableBottomSheetContent() -> TFYSwiftPopupView {
        let popup = TFYSwiftPopupView(frame: .zero)
        popup.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        popup.addSubview(scrollView)

        let title = UILabel()
        title.text = "嵌套 ScrollView"
        title.font = .preferredFont(forTextStyle: .headline)
        title.textAlignment = .center
        let hint = UILabel()
        hint.text = "先滚动列表；回到顶部后继续下拉可拖动面板"
        hint.font = .preferredFont(forTextStyle: .subheadline)
        hint.textColor = .secondaryLabel
        hint.textAlignment = .center
        hint.numberOfLines = 0
        let close = UIButton(type: .system)
        close.setTitle("关闭面板", for: .normal)
        close.addAction(UIAction { [weak popup] _ in popup?.dismissAnimated(true) }, for: .touchUpInside)

        let rows = (1...20).map { index -> UIView in
            let label = UILabel()
            label.text = "滚动内容 \(index)"
            label.font = .preferredFont(forTextStyle: .body)
            label.backgroundColor = index.isMultiple(of: 2) ? .secondarySystemBackground : .systemBackground
            label.heightAnchor.constraint(equalToConstant: 44).isActive = true
            return label
        }
        let stack = UIStackView(arrangedSubviews: [title, hint] + rows + [close])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: popup.topAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: popup.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: popup.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: popup.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
        ])
        return popup
    }
}
