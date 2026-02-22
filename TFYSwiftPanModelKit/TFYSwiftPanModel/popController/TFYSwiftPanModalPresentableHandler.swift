//
//  TFYSwiftPanModalPresentableHandler.swift
//  TFYSwiftPanModel
//
//  弹窗手势与状态管理，由 OC TFYPanModalPresentableHandler 迁移。
//

import UIKit

public enum TFYPanModalPresentableHandlerMode: UInt {
    case viewController = 0
    case view
}

/// Handler 事件代理
public protocol TFYSwiftPanModalPresentableHandlerDelegate: AnyObject {
    func adjustPresentableYPos(_ yPos: CGFloat)
    func presentableTransition(to state: PresentationState)
    func currentHandlerPresentationState() -> PresentationState
    func dismiss(_ isInteractive: Bool, mode: PanModalInteractiveMode)
    func cancelInteractiveTransition()
    func finishInteractiveTransition()
}

public extension TFYSwiftPanModalPresentableHandlerDelegate {
    func cancelInteractiveTransition() {}
    func finishInteractiveTransition() {}
}

/// Handler 数据源
public protocol TFYSwiftPanModalPresentableHandlerDataSource: AnyObject {
    func containerSize() -> CGSize
    func isBeingDismissed() -> Bool
    func isBeingPresented() -> Bool
    func isFormPositionAnimating() -> Bool
    func isPresentedViewAnchored() -> Bool
    func isPresentedControllerInteractive() -> Bool
}

public extension TFYSwiftPanModalPresentableHandlerDataSource {
    func isPresentedViewAnchored() -> Bool { false }
    func isPresentedControllerInteractive() -> Bool { false }
}

private let scrollViewContentOffsetKeyPath = "contentOffset"

/// 弹窗核心手势与状态管理
public final class TFYSwiftPanModalPresentableHandler: NSObject, UIGestureRecognizerDelegate {

    public private(set) var shortFormYPosition: CGFloat = 0
    public private(set) var mediumFormYPosition: CGFloat = 0
    public private(set) var longFormYPosition: CGFloat = 0
    public private(set) var extendsPanScrolling: Bool = true
    public private(set) var anchorModalToLongForm: Bool = true
    public var anchoredYPosition: CGFloat {
        let top = presentable?.topOffset() ?? 0
        return anchorModalToLongForm ? longFormYPosition : top
    }

    public private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let g = UIPanGestureRecognizer(target: self, action: #selector(didPanOnView(_:)))
        g.minimumNumberOfTouches = 1
        g.maximumNumberOfTouches = 1
        g.delegate = self
        return g
    }()

    public private(set) lazy var screenEdgeGestureRecognizer: UIPanGestureRecognizer = {
        let g = UIPanGestureRecognizer(target: self, action: #selector(screenEdgeInteractiveAction(_:)))
        g.minimumNumberOfTouches = 1
        g.maximumNumberOfTouches = 1
        g.delegate = self
        return g
    }()

    public var mode: TFYPanModalPresentableHandlerMode = .viewController
    public weak var dragIndicatorView: (UIView & TFYSwiftPanModalIndicatorProtocol)?
    public weak var presentedView: UIView?
    public weak var presentable: (AnyObject & TFYSwiftPanModalPresentable)?
    public weak var delegate: TFYSwiftPanModalPresentableHandlerDelegate?
    public weak var dataSource: TFYSwiftPanModalPresentableHandlerDataSource?

    private var observerToken: TFYSwiftKeyValueObserver?
    private var scrollViewYOffset: CGFloat = 0
    private var keyboardObserved = false

    public init(presentable: AnyObject & TFYSwiftPanModalPresentable) {
        self.presentable = presentable
        super.init()
        addKeyboardObserver()
    }

    public static func handler(presentable: AnyObject & TFYSwiftPanModalPresentable) -> TFYSwiftPanModalPresentableHandler {
        TFYSwiftPanModalPresentableHandler(presentable: presentable)
    }

    @objc private func didPanOnView(_ pan: UIPanGestureRecognizer) {
        if shouldResponseToPanGesture(pan), keyboardInfo == nil {
            switch pan.state {
            case .began, .changed: handlePanGestureBeginOrChanged(pan)
            case .ended, .cancelled, .failed: handlePanGestureEnded(pan)
            default: break
            }
        } else {
            handlePanGestureDidNotResponse(pan)
        }
        presentable?.didRespondToPanModalGestureRecognizer(pan)
    }

    private func shouldResponseToPanGesture(_ pan: UIPanGestureRecognizer) -> Bool {
        if presentable?.shouldRespondToPanModalGestureRecognizer(pan) == true ||
            (pan.state != .began && pan.state != .cancelled) {
            return !shouldFailPanGesture(pan)
        }
        pan.isEnabled = false
        pan.isEnabled = true
        return false
    }

    private func shouldFailPanGesture(_ pan: UIPanGestureRecognizer) -> Bool {
        if shouldPrioritizePanGesture(pan) {
            presentable?.panScrollable()?.panGestureRecognizer.isEnabled = false
            presentable?.panScrollable()?.panGestureRecognizer.isEnabled = true
            return false
        }
        if shouldHandleShortStatePullDown(pan) { return true }
        guard let scrollView = presentable?.panScrollable() else { return false }
        let shouldFail = scrollView.contentOffset.y > -max(scrollView.contentInset.top, 0)
        if isPresentedViewAnchored(), shouldFail, let pv = presentedView {
            let loc = pan.location(in: pv)
            let flag = scrollView.frame.contains(loc) || scrollView.isScrolling
            if flag { dragIndicatorView?.didChange(to: .normal) }
            return flag
        }
        return false
    }

    private func shouldHandleShortStatePullDown(_ recognizer: UIPanGestureRecognizer) -> Bool {
        if presentable?.allowsPullDownWhenShortState() == true { return false }
        let loc = recognizer.translation(in: presentedView)
        if delegate?.currentHandlerPresentationState() == .short, recognizer.state == .began { return true }
        guard let pv = presentedView else { return false }
        if (pv.frame.origin.y >= shortFormYPosition || pv.frame.origin.y.isNearlyEqual(to: shortFormYPosition)), loc.y > 0 {
            return true
        }
        return false
    }

    private func shouldPrioritizePanGesture(_ recognizer: UIPanGestureRecognizer) -> Bool {
        recognizer.state == .began && (presentable?.shouldPrioritizePanModalGestureRecognizer(recognizer) ?? false)
    }

    private func handlePanGestureBeginOrChanged(_ pan: UIPanGestureRecognizer) {
        let velocity = pan.velocity(in: presentedView)
        respondToPanGesture(pan)
        if pan.state == .began, (presentable?.presentingVCAnimationStyle().rawValue ?? 0) > 0, velocity.y > 0,
           let pv = presentedView, (pv.frame.origin.y > shortFormYPosition || pv.frame.origin.y.isNearlyEqual(to: shortFormYPosition)) {
            dismissPresentable(true, mode: .dragDown)
        }
        if let pv = presentedView, pv.frame.origin.y.isNearlyEqual(to: anchoredYPosition), extendsPanScrolling {
            presentable?.willTransition(to: .long)
        }
        if pan.state == .changed {
            if velocity.y > 0 { dragIndicatorView?.didChange(to: .pullDown) }
            else if velocity.y < 0, (presentedView?.frame.origin.y ?? 0) <= anchoredYPosition, !extendsPanScrolling {
                dragIndicatorView?.didChange(to: .normal)
            }
        }
    }

    private func respondToPanGesture(_ pan: UIPanGestureRecognizer) {
        presentable?.willRespondToPanModalGestureRecognizer(pan)
        let yDisplacement = pan.translation(in: presentedView).y
        var dy = yDisplacement
        if (presentedView?.frame.origin.y ?? 0) < longFormYPosition { dy = yDisplacement / 2 }
        if let pv = presentedView {
            delegate?.adjustPresentableYPos(pv.frame.origin.y + dy)
        }
        pan.setTranslation(.zero, in: presentedView)
    }

    private func handlePanGestureEnded(_ pan: UIPanGestureRecognizer) {
        let velocity = pan.velocity(in: presentedView).y
        if abs(velocity) > (presentable?.minVerticalVelocityToTriggerDismiss() ?? 300) {
            let state = delegate?.currentHandlerPresentationState() ?? .short
            if velocity < 0 { handleDragUpState(state) }
            else { handleDragDownState(state) }
        } else {
            let pos = nearestDistance((presentedView?.frame.minY ?? 0), in: [CGFloat(containerSize().height), shortFormYPosition, longFormYPosition, mediumFormYPosition])
            if pos.isNearlyEqual(to: longFormYPosition) { transitionToState(.long); cancelInteractiveTransition() }
            else if pos.isNearlyEqual(to: mediumFormYPosition) { transitionToState(.medium); cancelInteractiveTransition() }
            else if pos.isNearlyEqual(to: shortFormYPosition) || (presentable?.allowsDragToDismiss() == false) {
                transitionToState(.short); cancelInteractiveTransition()
            } else {
                if isBeingDismissed() { finishInteractiveTransition() }
                else { dismissPresentable(false, mode: .none) }
            }
        }
        presentable?.didEndRespondToPanModalGestureRecognizer(pan)
    }

    private func handleDragUpState(_ state: PresentationState) {
        switch state {
        case .long: transitionToState(.long); cancelInteractiveTransition()
        case .medium: transitionToState(.long); cancelInteractiveTransition()
        case .short: transitionToState(.medium); cancelInteractiveTransition()
        }
    }

    private func handleDragDownState(_ state: PresentationState) {
        switch state {
        case .long: transitionToState(.medium); cancelInteractiveTransition()
        case .medium: transitionToState(.short); cancelInteractiveTransition()
        case .short:
            if presentable?.allowsDragToDismiss() == false { transitionToState(.short); cancelInteractiveTransition() }
            else { if isBeingDismissed() { finishInteractiveTransition() } else { dismissPresentable(false, mode: .none) } }
        }
    }

    private func handlePanGestureDidNotResponse(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .ended, .cancelled, .failed:
            dragIndicatorView?.didChange(to: .normal)
            cancelInteractiveTransition()
        default: break
        }
        pan.setTranslation(.zero, in: pan.view)
    }

    private func nearestDistance(_ position: CGFloat, in distances: [CGFloat]) -> CGFloat {
        if distances.isEmpty { return position }
        var minDiff = CGFloat.greatestFiniteMagnitude
        var nearest = position
        for d in distances {
            let diff = abs(d - position)
            if diff < minDiff { minDiff = diff; nearest = d }
        }
        return nearest
    }

    @objc private func screenEdgeInteractiveAction(_ g: UIPanGestureRecognizer) {}

    // MARK: - ScrollView KVO
    public func observeScrollable() {
        guard let scrollView = presentable?.panScrollable() else {
            observerToken?.unobserve()
            observerToken = nil
            return
        }
        observerToken?.unobserve()
        scrollViewYOffset = max(scrollView.contentOffset.y, -max(scrollView.contentInset.top, 0))
        observerToken = TFYSwiftKeyValueObserver.observe(scrollView, keyPath: scrollViewContentOffsetKeyPath, options: [.old]) { [weak self] _ in
            self?.didPanOnScrollViewChanged()
        }
    }

    private func didPanOnScrollViewChanged() {
        guard let scrollView = presentable?.panScrollable() else { return }
        if (!isBeingDismissed() && !isBeingPresented()) || (isBeingDismissed() && isPresentedControllerInteractive()) {
            if !isPresentedViewAnchored(), scrollView.contentOffset.y > 0 { haltScrolling(scrollView) }
            else if scrollView.isScrolling || isPresentedViewAnimating() {
                if isPresentedViewAnchored() { trackScrolling(scrollView) }
                else { haltScrolling(scrollView) }
            } else { trackScrolling(scrollView) }
        } else if isBeingPresented() {
            setScrollableContentOffset(scrollView.contentOffset, animated: true)
        }
    }

    private func trackScrolling(_ scrollView: UIScrollView) {
        scrollViewYOffset = max(scrollView.contentOffset.y, -max(scrollView.contentInset.top, 0))
        scrollView.showsVerticalScrollIndicator = presentable?.showsScrollableVerticalScrollIndicator() ?? true
    }

    private func haltScrolling(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 || scrollViewYOffset <= scrollView.contentOffset.y {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollViewYOffset), animated: false)
            scrollView.showsVerticalScrollIndicator = false
        }
    }

    public func configureScrollViewInsets() {
        guard let scrollView = presentable?.panScrollable(), !scrollView.isScrolling else { return }
        scrollView.showsVerticalScrollIndicator = presentable?.showsScrollableVerticalScrollIndicator() ?? true
        scrollView.isScrollEnabled = presentable?.isPanScrollEnabled() ?? true
        scrollView.scrollIndicatorInsets = presentable?.scrollIndicatorInsets() ?? .zero
        if presentable?.shouldAutoSetPanScrollContentInset() == true {
            var insets = scrollView.contentInset
            var bottom: CGFloat = 0
            for scene in UIApplication.shared.connectedScenes {
                guard let ws = scene as? UIWindowScene, ws.activationState == .foregroundActive,
                      let w = ws.windows.first(where: { $0.isKeyWindow }) else { continue }
                bottom = w.safeAreaInsets.bottom
                break
            }
            if insets.bottom.isNearZero || insets.bottom < bottom {
                insets.bottom = bottom
                scrollView.contentInset = insets
            }
            scrollView.contentInsetAdjustmentBehavior = .never
        }
    }

    public func setScrollableContentOffset(_ offset: CGPoint, animated: Bool) {
        guard let scrollView = presentable?.panScrollable() else { return }
        observerToken?.unobserve()
        scrollView.setContentOffset(offset, animated: animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.3 : 0.1)) { [weak self] in
            self?.trackScrolling(scrollView)
            self?.observeScrollable()
        }
    }

    public func configureViewLayout() {
        if let vc = presentable as? UIViewController {
            shortFormYPosition = vc.shortFormYPos
            mediumFormYPosition = vc.mediumFormYPos
            longFormYPosition = vc.longFormYPos
            anchorModalToLongForm = presentable?.anchorModalToLongForm() ?? true
            extendsPanScrolling = presentable?.allowsExtendedPanScrolling() ?? true
        } else if let contentView = presentable as? TFYSwiftPanModalContentView {
            shortFormYPosition = contentView.shortFormYPos
            mediumFormYPosition = contentView.mediumFormYPos
            longFormYPosition = contentView.longFormYPos
            anchorModalToLongForm = presentable?.anchorModalToLongForm() ?? true
            extendsPanScrolling = presentable?.allowsExtendedPanScrolling() ?? true
        }
    }

    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        if let p = presentable as? TFYSwiftPanModalPanGestureDelegate {
            return p.panGestureRecognizer(gestureRecognizer, shouldRecognizeSimultaneouslyWith: other)
        }
        return (gestureRecognizer is UIPanGestureRecognizer) && (other is UIPanGestureRecognizer)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer) -> Bool {
        if let p = presentable as? TFYSwiftPanModalPanGestureDelegate {
            return p.panGestureRecognizer(gestureRecognizer, shouldBeRequiredToFailBy: other)
        }
        return gestureRecognizer === screenEdgeGestureRecognizer && (other is UIPanGestureRecognizer)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf other: UIGestureRecognizer) -> Bool {
        (presentable as? TFYSwiftPanModalPanGestureDelegate)?.panGestureRecognizer(gestureRecognizer, shouldRequireFailureOf: other) ?? false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let p = presentable as? TFYSwiftPanModalPanGestureDelegate {
            return p.panGestureRecognizerShouldBegin(gestureRecognizer)
        }
        if gestureRecognizer === screenEdgeGestureRecognizer {
            let velocity = screenEdgeGestureRecognizer.velocity(in: screenEdgeGestureRecognizer.view)
            if velocity.x <= 0 || velocity.x.isNearlyEqual(to: 0) { return false }
            let loc = screenEdgeGestureRecognizer.location(in: screenEdgeGestureRecognizer.view)
            let threshold = presentable?.maxAllowedDistanceToLeftScreenEdgeForPanInteraction() ?? 0
            if threshold > 0, loc.x > threshold { return false }
            if velocity.x > 0, velocity.y.isNearlyEqual(to: 0) { return true }
            if velocity.x > 0, velocity.y != 0, velocity.x / abs(velocity.y) > 2 { return true }
            return false
        }
        return true
    }

    // MARK: - Keyboard
    private var keyboardInfo: [AnyHashable: Any]?
    private func addKeyboardObserver() {
        guard !keyboardObserved, presentable?.isAutoHandleKeyboardEnabled() == true else { return }
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        keyboardObserved = true
    }

    private func removeKeyboardObserver() {
        guard keyboardObserved else { return }
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        keyboardObserved = false
    }

    @objc private func keyboardWillShow(_ n: Notification) {
        guard findCurrentTextInput(in: presentedView) != nil else { return }
        keyboardInfo = n.userInfo
        updatePanContainerFrameForKeyboard()
    }

    @objc private func keyboardWillHide(_ n: Notification) {
        keyboardInfo = nil
        let userInfo = n.userInfo ?? [:]
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.presentedView?.transform = .identity
        }
    }

    private func updatePanContainerFrameForKeyboard() {
        guard keyboardInfo != nil, let textInput = findCurrentTextInput(in: presentedView), let pv = presentedView else { return }
        let lastTransform = pv.transform
        pv.transform = .identity
        let textBottomY = textInput.convert(textInput.bounds, to: pv).maxY
        let keyboardHeight = (keyboardInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
        let top = presentable?.keyboardOffsetFromInputView() ?? 5
        let offsetY = pv.panHeight - (keyboardHeight + top + textBottomY + pv.panTop)
        pv.transform = lastTransform
        let duration = (keyboardInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveValue = (keyboardInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curveValue << 16)) {
            pv.transform = CGAffineTransform(translationX: 0, y: offsetY)
        }
    }

    private func findCurrentTextInput(in view: UIView?) -> UIView? {
        guard let view = view else { return nil }
        if view is UIKeyInput, view.isFirstResponder {
            if type(of: view).description().contains("WebBrowserView") || type(of: view).description().contains("WKContentView") { return nil }
            return view
        }
        for sub in view.subviews {
            if let found = findCurrentTextInput(in: sub) { return found }
        }
        return nil
    }

    // MARK: - Delegate/DataSource helpers
    private func transitionToState(_ state: PresentationState) { delegate?.presentableTransition(to: state) }
    private func cancelInteractiveTransition() { delegate?.cancelInteractiveTransition() }
    private func finishInteractiveTransition() { delegate?.finishInteractiveTransition() }
    private func dismissPresentable(_ interactive: Bool, mode: PanModalInteractiveMode) { delegate?.dismiss(interactive, mode: mode) }

    private func isPresentedViewAnchored() -> Bool { dataSource?.isPresentedViewAnchored() ?? false }
    private func isBeingDismissed() -> Bool { dataSource?.isBeingDismissed() ?? false }
    private func isBeingPresented() -> Bool { dataSource?.isBeingPresented() ?? false }
    private func isPresentedControllerInteractive() -> Bool { dataSource?.isPresentedControllerInteractive() ?? false }
    private func isPresentedViewAnimating() -> Bool { dataSource?.isFormPositionAnimating() ?? false }
    private func containerSize() -> CGSize { dataSource?.containerSize() ?? .zero }

    deinit {
        removeKeyboardObserver()
        observerToken?.unobserve()
        observerToken = nil
    }
}
