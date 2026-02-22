//
//  TFYSwiftPanModalContainerView.swift
//  TFYSwiftPanModel
//
//  PanModal 容器视图（用于在 View 上 present 内容），由 OC TFYPanModalContainerView 迁移。
//

import UIKit

/// PanModal 弹窗容器视图，负责内容视图的展示、布局、动画
public final class TFYSwiftPanModalContainerView: UIView, TFYSwiftPanModalPresentableHandlerDelegate, TFYSwiftPanModalPresentableHandlerDataSource {

    public private(set) var backgroundView: TFYSwiftDimmedView!
    public private(set) var modalPanContainerView: TFYSwiftPanContainerView!
    public private(set) var currentPresentationState: PresentationState = .short

    private let contentView: TFYSwiftPanModalContentView
    private weak var presentingView: UIView?
    private var handler: TFYSwiftPanModalPresentableHandler!
    private var isPresentedViewAnimating = false
    private var isPresenting = false
    private var isDismissing = false
    private var dragIndicatorView: (UIView & TFYSwiftPanModalIndicatorProtocol)?
    private var animationBlock: (() -> Void)?

    public init(presentingView: UIView, contentView: TFYSwiftPanModalContentView) {
        self.presentingView = presentingView
        self.contentView = contentView
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func show() {
        prepare()
        presentAnimationWillBegin()
        beginPresentAnimation()
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        if animated {
            animationBlock = completion
            dismiss(false, mode: .none)
        } else {
            isDismissing = true
            contentView.panModalWillDismiss()
            removeFromSuperview()
            contentView.panModalDidDismiss()
            completion?()
            isDismissing = false
        }
    }

    public func setNeedsLayoutUpdate() {
        handler.configureViewLayout()
        isUserInteractionEnabled = contentView.isUserInteractionEnabled()
        backgroundView.blurTintColor = contentView.backgroundConfig().blurTintColor
        handler.observeScrollable()
        adjustPresentedViewFrame()
        handler.configureScrollViewInsets()
        updateContainerViewShadow()
        updateDragIndicatorView()
        updateRoundedCorners()
    }

    public func updateUserHitBehavior() {
        backgroundView.isUserInteractionEnabled = contentView.allowsTapBackgroundToDismiss()
    }

    public func transition(to state: PresentationState, animated: Bool) {
        if contentView.shouldTransition(to: state) == false { return }
        dragIndicatorView?.didChange(to: .normal)
        contentView.willTransition(to: state)
        let yPos: CGFloat
        switch state {
        case .long: yPos = handler.longFormYPosition
        case .medium: yPos = handler.mediumFormYPosition
        case .short: yPos = handler.shortFormYPosition
        }
        snapToYPos(yPos, animated: animated)
        currentPresentationState = state
        contentView.didChangeTransition(to: state)
    }

    public func setScrollableContentOffset(_ offset: CGPoint, animated: Bool) {
        handler.setScrollableContentOffset(offset, animated: animated)
    }

    private var presentable: TFYSwiftPanModalPresentable? { contentView }

    private func prepare() {
        guard let pv = presentingView else { return }
        pv.addSubview(self)
        frame = pv.bounds
        handler?.delegate = nil
        handler?.dataSource = nil
        handler = TFYSwiftPanModalPresentableHandler(presentable: contentView)
        handler.delegate = self
        handler.dataSource = self
        let config = contentView.backgroundConfig()
        backgroundView = TFYSwiftDimmedView(backgroundConfig: config)
        modalPanContainerView = TFYSwiftPanContainerView(presentedView: contentView, frame: bounds)
    }

    private func presentAnimationWillBegin() {
        contentView.panModalTransitionWillBegin()
        addSubview(backgroundView)
        backgroundView.frame = bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let originState = contentView.originPresentationState()
        if originState == .long { currentPresentationState = .long }
        else if originState == .medium { currentPresentationState = .medium }
        addSubview(modalPanContainerView)
        handler.presentedView = modalPanContainerView
        if contentView.allowsTouchEventsPassingThroughTransitionView() {
            modalPanContainerView.addGestureRecognizer(handler.panGestureRecognizer)
        } else {
            addGestureRecognizer(handler.panGestureRecognizer)
        }
        setNeedsLayoutUpdate()
        contentView.presentedViewDidMoveToSuperView()
    }

    private func beginPresentAnimation() {
        isPresenting = true
        handler.configureViewLayout()
        let originState = contentView.originPresentationState()
        var yPos = contentView.shortFormYPos
        if originState == .long { yPos = contentView.longFormYPos }
        else if originState == .medium { yPos = contentView.mediumFormYPos }
        adjustPresentedViewFrame()
        modalPanContainerView.panTop = bounds.height
        TFYSwiftPanModalAnimator.animate({ [weak self] in
            self?.modalPanContainerView.panTop = yPos
            self?.backgroundView.dimState = .max
        }, config: contentView) { [weak self] _ in
            self?.isPresenting = false
            self?.contentView.panModalTransitionDidFinish()
        }
    }

    private func adjustPresentedViewFrame() {
        let size = CGSize(width: bounds.width, height: bounds.height - handler.anchoredYPosition)
        modalPanContainerView.panSize = frame.size
        modalPanContainerView.contentView.frame = CGRect(origin: .zero, size: size)
        contentView.frame = modalPanContainerView.contentView.bounds
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
    }

    private func updateContainerViewShadow() {
        let shadow = contentView.contentShadow()
        if shadow.shadowColor.cgColor.alpha > 0 {
            modalPanContainerView.updateShadow(color: shadow.shadowColor, radius: shadow.shadowRadius, offset: shadow.shadowOffset, opacity: Float(shadow.shadowOpacity))
        } else {
            modalPanContainerView.clearShadow()
        }
    }

    private func updateDragIndicatorView() {
        if contentView.showDragIndicator() {
            addDragIndicatorView()
        } else {
            dragIndicatorView?.isHidden = true
        }
    }

    private func addDragIndicatorView() {
        if dragIndicatorView == nil {
            dragIndicatorView = contentView.customIndicatorView() ?? TFYSwiftPanIndicatorView()
        }
        dragIndicatorView?.isHidden = false
        handler.dragIndicatorView = dragIndicatorView
        if dragIndicatorView?.superview != modalPanContainerView {
            if let indicator = dragIndicatorView {
                modalPanContainerView.addSubview(indicator)
                indicator.setupSubviews()
            }
        }
        updateDragIndicatorViewFrame()
        dragIndicatorView?.didChange(to: .normal)
    }

    private func updateDragIndicatorViewFrame() {
        guard let ind = dragIndicatorView else { return }
        let sz = ind.indicatorSize()
        ind.frame = CGRect(x: (modalPanContainerView.panWidth - sz.width) / 2, y: -PanModalIndicatorConstants.yOffset - sz.height, width: sz.width, height: sz.height)
    }

    private func updateRoundedCorners() {
        let contentSubview = modalPanContainerView.contentView
        if presentable?.shouldRoundTopCorners() == true {
            let radius = presentable?.cornerRadius() ?? 8
            let path = UIBezierPath(roundedRect: contentSubview.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: radius, height: radius))
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
            }, config: contentView) { [weak self] _ in
                self?.isPresentedViewAnimating = false
            }
        } else {
            adjustToYPos(yPos)
        }
    }

    private func adjustToYPos(_ yPos: CGFloat) {
        modalPanContainerView.panTop = max(yPos, handler.anchoredYPosition)
        if modalPanContainerView.frame.origin.y >= handler.shortFormYPosition {
            let yDist = modalPanContainerView.frame.origin.y - handler.shortFormYPosition
            let bottomH = bounds.height - handler.shortFormYPosition
            let percent = bottomH > 0 ? min(1, yDist / bottomH) : 0
            backgroundView.dimState = .percent
            backgroundView.percent = 1 - percent
            contentView.panModalGestureRecognizer(handler.panGestureRecognizer, dismissPercent: percent)
        } else {
            backgroundView.dimState = .max
        }
    }

    // MARK: - TFYSwiftPanModalPresentableHandlerDelegate
    public func adjustPresentableYPos(_ yPos: CGFloat) { adjustToYPos(yPos) }
    public func presentableTransition(to state: PresentationState) { transition(to: state, animated: true) }
    public func currentHandlerPresentationState() -> PresentationState { currentPresentationState }
    public func dismiss(_ isInteractive: Bool, mode: PanModalInteractiveMode) {
        handler.panGestureRecognizer.isEnabled = false
        isDismissing = true
        contentView.panModalWillDismiss()
        TFYSwiftPanModalAnimator.dismissAnimate({ [weak self] in
            self?.modalPanContainerView.panTop = self?.bounds.height ?? 0
            self?.backgroundView.dimState = .off
            self?.dragIndicatorView?.alpha = 0
        }, config: contentView) { [weak self] _ in
            self?.removeFromSuperview()
            self?.contentView.panModalDidDismiss()
            self?.animationBlock?()
            self?.animationBlock = nil
            self?.isDismissing = false
        }
    }

    // MARK: - TFYSwiftPanModalPresentableHandlerDataSource
    public func containerSize() -> CGSize { presentingView?.bounds.size ?? .zero }
    public func isBeingDismissed() -> Bool { isDismissing }
    public func isBeingPresented() -> Bool { isPresenting }
    public func isFormPositionAnimating() -> Bool { isPresentedViewAnimating }
    public func isPresentedViewAnchored() -> Bool {
        if contentView.shouldRespondToPanModalGestureRecognizer(handler.panGestureRecognizer) == false { return true }
        let y = modalPanContainerView.frame.minY
        return !isPresentedViewAnimating && handler.extendsPanScrolling && (y <= handler.anchoredYPosition || y.isNearlyEqual(to: handler.anchoredYPosition))
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        handler.configureViewLayout()
    }
}
