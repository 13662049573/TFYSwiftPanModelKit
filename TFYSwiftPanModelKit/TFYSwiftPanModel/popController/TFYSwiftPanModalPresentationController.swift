//
//  TFYSwiftPanModalPresentationController.swift
//  TFYSwiftPanModel
//
//  PanModal 自定义 UIPresentationController，完整实现手势/布局/状态切换。
//

import UIKit

/// PanModal 弹窗的 UIPresentationController
public final class TFYSwiftPanModalPresentationController: UIPresentationController,
    TFYSwiftPanModalPresentableHandlerDelegate,
    TFYSwiftPanModalPresentableHandlerDataSource {

    public private(set) lazy var backgroundView: TFYSwiftDimmedView = {
        let config = presentedViewController.backgroundConfig()
        return TFYSwiftDimmedView(backgroundConfig: config)
    }()

    public private(set) var currentPresentationState: PresentationState = .short
    public private(set) var isPresentedViewAnimating: Bool = false

    public private(set) lazy var frequentTapPrevention: TFYSwiftPanModalFrequentTapPrevention = {
        let interval = presentedViewController.frequentTapPreventionInterval()
        let p = TFYSwiftPanModalFrequentTapPrevention(preventionInterval: interval)
        p.enabled = presentedViewController.shouldPreventFrequentTapping()
        return p
    }()

    weak var presentationDelegate: TFYSwiftPanModalPresentationDelegate?

    private var handler: TFYSwiftPanModalPresentableHandler!
    private var dragIndicatorView: (UIView & TFYSwiftPanModalIndicatorProtocol)?
    private var isDismissing = false
    private var isPresenting = true

    private lazy var panContainerView: TFYSwiftPanContainerView = {
        let frame = containerView?.bounds ?? .zero
        return TFYSwiftPanContainerView(presentedView: presentedViewController.view, frame: frame)
    }()

    private var presentable: TFYSwiftPanModalPresentable { presentedViewController }

    /// Animator 读取这个 view；在 willBegin 里我们把 panTop 设到目标 Y
    public override var presentedView: UIView { panContainerView }

    /// Animator 会调用这个获取 presentedView 的最终 frame
    /// 返回 containerView.bounds 但 y 设为目标位置
    public override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        var frame = containerView.bounds
        let targetY = targetPresentationY()
        frame.origin.y = targetY
        return frame
    }

    public override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        handler = TFYSwiftPanModalPresentableHandler(presentable: presentedViewController)
        handler.mode = .viewController
        handler.delegate = self
        handler.dataSource = self
    }

    /// 根据初始状态计算目标 Y 位置
    private func targetPresentationY() -> CGFloat {
        handler.configureViewLayout()
        let origin = presentable.originPresentationState()
        switch origin {
        case .long: return handler.longFormYPosition
        case .medium: return handler.mediumFormYPosition
        case .short: return handler.shortFormYPosition
        }
    }

    // MARK: - Public API
    public func setNeedsLayoutUpdate() {
        handler.configureViewLayout()
        isUserInteractionEnabled = presentable.isUserInteractionEnabled()
        backgroundView.blurTintColor = presentable.backgroundConfig().blurTintColor
        handler.observeScrollable()
        adjustPresentedViewFrame()
        handler.configureScrollViewInsets()
        updateContainerViewShadow()
        updateDragIndicatorView()
        updateRoundedCorners()
    }

    public func updateUserHitBehavior() {
        backgroundView.isUserInteractionEnabled = presentable.allowsTapBackgroundToDismiss()
    }

    public func transition(to state: PresentationState, animated: Bool) {
        guard presentable.shouldTransition(to: state) else { return }
        dragIndicatorView?.didChange(to: .normal)
        presentable.willTransition(to: state)
        let yPos: CGFloat
        switch state {
        case .long: yPos = handler.longFormYPosition
        case .medium: yPos = handler.mediumFormYPosition
        case .short: yPos = handler.shortFormYPosition
        }
        snapToYPos(yPos, animated: animated)
        currentPresentationState = state
        presentable.didChangeTransition(to: state)
    }

    public func setScrollableContentOffset(_ offset: CGPoint, animated: Bool) {
        handler.setScrollableContentOffset(offset, animated: animated)
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        presentedViewController.dismiss(animated: animated, completion: completion)
    }

    public func canExecutePanModalAction() -> Bool { frequentTapPrevention.canExecute() }

    @discardableResult
    public func executePanModalActionIfAllowed(block: () -> Void) -> Bool {
        frequentTapPrevention.executeIfAllowed(block: block)
    }

    private var isUserInteractionEnabled: Bool = true {
        didSet { panContainerView.isUserInteractionEnabled = isUserInteractionEnabled }
    }

    // MARK: - UIPresentationController Overrides
    public override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        // 1. 背景
        backgroundView.frame = containerView.bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.tapBlock = { [weak self] _ in
            guard let self, self.presentable.allowsTapBackgroundToDismiss() else { return }
            self.presentedViewController.dismiss(animated: true)
        }
        containerView.insertSubview(backgroundView, at: 0)

        // 2. 计算目标位置，设定 panContainerView 的 frame
        handler.configureViewLayout()
        let originState = presentable.originPresentationState()
        if originState == .long { currentPresentationState = .long }
        else if originState == .medium { currentPresentationState = .medium }

        // 先设定 panContainerView 全尺寸，然后在 Animator 中从底部滑入
        panContainerView.frame = containerView.bounds
        handler.presentedView = panContainerView

        // 计算目标 Y 并设到 panContainerView 上
        // Animator 在 animatePresentation 里会先读取 targetY = frame.origin.y，
        // 然后把 y 设到屏幕底部，再动画回 targetY
        let targetY = targetPresentationY()
        panContainerView.panTop = targetY

        // 3. 布局 presentedVC.view
        adjustPresentedViewFrame()

        // 4. 手势
        if presentable.allowsTouchEventsPassingThroughTransitionView() {
            panContainerView.addGestureRecognizer(handler.panGestureRecognizer)
        } else {
            containerView.addGestureRecognizer(handler.panGestureRecognizer)
        }

        // 5. 背景动画
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.backgroundView.dimState = .max
            })
        } else {
            backgroundView.dimState = .max
        }

        presentable.panModalTransitionWillBegin()
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            isPresenting = false
            setNeedsLayoutUpdate()
            presentable.presentedViewDidMoveToSuperView()
            presentable.panModalTransitionDidFinish()
        } else {
            backgroundView.removeFromSuperview()
        }
    }

    public override func dismissalTransitionWillBegin() {
        isDismissing = true
        presentable.panModalWillDismiss()
        if let coordinator = presentedViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.backgroundView.dimState = .off
                self.dragIndicatorView?.alpha = 0
            })
        } else {
            backgroundView.dimState = .off
            dragIndicatorView?.alpha = 0
        }
    }

    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            presentable.panModalDidDismiss()
            presentationDelegate?.strongPresentationController = nil
        }
        isDismissing = false
    }

    public override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        guard let containerView = containerView else { return }
        backgroundView.frame = containerView.bounds
    }

    public override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        if !isPresenting {
            handler.configureViewLayout()
            adjustPresentedViewFrame()
            updateRoundedCorners()
        }
    }

    // MARK: - Layout
    private func adjustPresentedViewFrame() {
        guard let containerView = containerView else { return }
        let size = CGSize(width: containerView.bounds.width,
                          height: containerView.bounds.height - handler.anchoredYPosition)
        panContainerView.panSize = containerView.bounds.size
        panContainerView.contentView.frame = CGRect(origin: .zero, size: size)
        presentedViewController.view.frame = panContainerView.contentView.bounds
        presentedViewController.view.setNeedsLayout()
        presentedViewController.view.layoutIfNeeded()
    }

    private func updateContainerViewShadow() {
        let shadow = presentable.contentShadow()
        if shadow.shadowColor.cgColor.alpha > 0 {
            panContainerView.updateShadow(color: shadow.shadowColor, radius: shadow.shadowRadius,
                                          offset: shadow.shadowOffset, opacity: Float(shadow.shadowOpacity))
        } else {
            panContainerView.clearShadow()
        }
    }

    private func updateDragIndicatorView() {
        if presentable.showDragIndicator() {
            addDragIndicatorView()
        } else {
            dragIndicatorView?.isHidden = true
        }
    }

    private func addDragIndicatorView() {
        if dragIndicatorView == nil {
            dragIndicatorView = presentable.customIndicatorView() ?? TFYSwiftPanIndicatorView()
        }
        dragIndicatorView?.isHidden = false
        handler.dragIndicatorView = dragIndicatorView
        if dragIndicatorView?.superview != panContainerView, let indicator = dragIndicatorView {
            panContainerView.addSubview(indicator)
            indicator.setupSubviews()
        }
        updateDragIndicatorViewFrame()
        dragIndicatorView?.didChange(to: .normal)
    }

    private func updateDragIndicatorViewFrame() {
        guard let ind = dragIndicatorView else { return }
        let sz = ind.indicatorSize()
        ind.frame = CGRect(x: (panContainerView.panWidth - sz.width) / 2,
                           y: -PanModalIndicatorConstants.yOffset - sz.height,
                           width: sz.width, height: sz.height)
    }

    private func updateRoundedCorners() {
        let contentSubview = panContainerView.contentView
        if presentable.shouldRoundTopCorners() {
            let radius = presentable.cornerRadius()
            let path = UIBezierPath(roundedRect: contentSubview.bounds,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            contentSubview.layer.mask = mask
        } else {
            contentSubview.layer.mask = nil
        }
    }

    private func snapToYPos(_ yPos: CGFloat, animated: Bool) {
        if animated {
            TFYSwiftPanModalAnimator.animate({ [weak self] in
                self?.isPresentedViewAnimating = true
                self?.adjustToYPos(yPos)
            }, config: presentable) { [weak self] _ in
                self?.isPresentedViewAnimating = false
            }
        } else {
            adjustToYPos(yPos)
        }
    }

    private func adjustToYPos(_ yPos: CGFloat) {
        panContainerView.panTop = max(yPos, handler.anchoredYPosition)
        if panContainerView.frame.origin.y >= handler.shortFormYPosition {
            let yDist = panContainerView.frame.origin.y - handler.shortFormYPosition
            let bottomH = (containerView?.bounds.height ?? 0) - handler.shortFormYPosition
            let percent = bottomH > 0 ? min(1, yDist / bottomH) : 0
            backgroundView.dimState = .percent
            backgroundView.percent = 1 - percent
            presentable.panModalGestureRecognizer(handler.panGestureRecognizer, dismissPercent: percent)
        } else {
            backgroundView.dimState = .max
        }
    }

    // MARK: - TFYSwiftPanModalPresentableHandlerDelegate
    public func adjustPresentableYPos(_ yPos: CGFloat) { adjustToYPos(yPos) }
    public func presentableTransition(to state: PresentationState) { transition(to: state, animated: true) }
    public func currentHandlerPresentationState() -> PresentationState { currentPresentationState }

    public func dismiss(_ isInteractive: Bool, mode: PanModalInteractiveMode) {
        if isInteractive {
            presentationDelegate?.interactive = true
            presentationDelegate?.interactiveMode = mode
        }
        presentedViewController.dismiss(animated: true)
    }

    public func cancelInteractiveTransition() {
        presentationDelegate?.interactive = false
        presentationDelegate?.interactiveDismissalAnimator.cancel()
    }

    public func finishInteractiveTransition() {
        presentationDelegate?.interactive = false
        presentationDelegate?.interactiveDismissalAnimator.finish()
    }

    // MARK: - TFYSwiftPanModalPresentableHandlerDataSource
    public func containerSize() -> CGSize { containerView?.bounds.size ?? .zero }
    public func isBeingDismissed() -> Bool { isDismissing || presentedViewController.isBeingDismissed }
    public func isBeingPresented() -> Bool { isPresenting || presentedViewController.isBeingPresented }
    public func isFormPositionAnimating() -> Bool { isPresentedViewAnimating }
    public func isPresentedViewAnchored() -> Bool {
        if presentable.shouldRespondToPanModalGestureRecognizer(handler.panGestureRecognizer) == false { return true }
        let y = panContainerView.frame.minY
        return !isPresentedViewAnimating && handler.extendsPanScrolling &&
            (y <= handler.anchoredYPosition || y.isNearlyEqual(to: handler.anchoredYPosition))
    }
}
