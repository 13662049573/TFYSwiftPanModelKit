//
//  TFYSwiftPanModelKitTests.swift
//  TFYSwiftPanModelKitTests
//

import XCTest
@testable import TFYSwiftPanModelKit

final class TFYSwiftKeyValueObserverTests: XCTestCase {

    final class ObservableObject: NSObject {
        @objc dynamic var value: Int = 0
    }

    func testUnobserveStopsCallbacks() {
        let object = ObservableObject()
        var callCount = 0
        let token = TFYSwiftKeyValueObserver.observe(object, keyPath: #keyPath(ObservableObject.value), options: [.new]) { _ in
            callCount += 1
        }
        XCTAssertNotNil(token)
        object.value = 1
        XCTAssertEqual(callCount, 1)

        token?.unobserve()
        object.value = 2
        XCTAssertEqual(callCount, 1, "unobserve should stop callbacks")

        // Idempotent
        token?.unobserve()
        object.value = 3
        XCTAssertEqual(callCount, 1)
    }
}

final class TFYSwiftFrequentTapPreventionTests: XCTestCase {

    private final class Delegate: TFYSwiftPanModalFrequentTapPreventionDelegate {
        var onStateChange: ((Bool, TimeInterval) -> Void)?

        func frequentTapPreventionStateChanged(isPrevented: Bool, remainingTime: TimeInterval) {
            onStateChange?(isPrevented, remainingTime)
        }
    }

    func testPreventionBlocksRapidTriggers() {
        let prevention = TFYSwiftPanModalFrequentTapPrevention(preventionInterval: 1.0)
        prevention.enabled = true
        XCTAssertTrue(prevention.canExecute())
        prevention.triggerPrevention()
        XCTAssertFalse(prevention.canExecute())
        XCTAssertGreaterThan(prevention.currentRemainingTime, 0)
    }

    func testDisabledAlwaysAllows() {
        let prevention = TFYSwiftPanModalFrequentTapPrevention(preventionInterval: 1.0)
        prevention.enabled = false
        prevention.triggerPrevention()
        XCTAssertTrue(prevention.canExecute())
    }

    func testNegativeIntervalIsClampedAndDoesNotPrevent() {
        let prevention = TFYSwiftPanModalFrequentTapPrevention(preventionInterval: -1)
        prevention.triggerPrevention()
        XCTAssertEqual(prevention.preventionInterval, 0)
        XCTAssertFalse(prevention.isPrevented)
        XCTAssertTrue(prevention.canExecute())
    }

    func testPreventionAutomaticallyResets() {
        let resetExpectation = expectation(description: "prevention resets")
        let prevention = TFYSwiftPanModalFrequentTapPrevention(preventionInterval: 0.02)
        let delegate = Delegate()
        delegate.onStateChange = { isPrevented, _ in
            if !isPrevented { resetExpectation.fulfill() }
        }
        prevention.delegate = delegate

        prevention.triggerPrevention()
        XCTAssertTrue(prevention.isPrevented)

        wait(for: [resetExpectation], timeout: 1)
        XCTAssertFalse(prevention.isPrevented)
        XCTAssertEqual(prevention.currentRemainingTime, 0)
    }
}

final class TFYSwiftPopupConfigurationTests: XCTestCase {

    func testValidateAcceptsDefaults() {
        let config = TFYSwiftPopupViewConfiguration()
        XCTAssertTrue(config.validate())
    }

    func testIsDismissibleFalseStillValid() {
        let config = TFYSwiftPopupViewConfiguration()
        config.isDismissible = false
        XCTAssertTrue(config.validate())
    }

    func testInvalidMaxPopupCount() {
        let config = TFYSwiftPopupViewConfiguration()
        config.maxPopupCount = 0
        XCTAssertFalse(config.validate())
    }

    func testNonFiniteValuesAreRejected() {
        let config = TFYSwiftPopupViewConfiguration()
        config.animationDuration = .infinity
        XCTAssertFalse(config.validate())

        config.animationDuration = 0.25
        config.safeAreaInsets.top = .nan
        XCTAssertFalse(config.validate())
    }

    func testContainerDimensionValidation() {
        let config = TFYSwiftPopupContainerConfiguration()
        config.width = .ratio(1.1)
        XCTAssertFalse(config.validate())

        config.width = .ratio(0.5)
        XCTAssertTrue(config.validate())
    }
}

final class TFYSwiftPopupPriorityTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.clearAllQueues()
        manager.maxSimultaneousPopups = 1
        manager.autoCleanupExpiredPopups = true
        manager.enforceMaxPopupCount(0)
    }

    override func tearDown() {
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.clearAllQueues()
        manager.maxSimultaneousPopups = 1
        manager.autoCleanupExpiredPopups = true
        manager.enforceMaxPopupCount(0)
        super.tearDown()
    }

    func testPriorityComparison() {
        XCTAssertTrue(TFYPopupPriority.isHigher(.urgent, than: .normal))
        XCTAssertFalse(TFYPopupPriority.isHigher(.low, than: .high))
    }

    func testFromValueClamps() {
        XCTAssertEqual(TFYPopupPriority.fromValue(200), .normal)
        XCTAssertEqual(TFYPopupPriority.fromValue(-10), .background)
        XCTAssertEqual(TFYPopupPriority.fromValue(9999), .urgent)
    }

    func testCanBeReplacedParameterIsStoredOnConfig() {
        let popup = TFYSwiftPopupView(frame: .zero)
        popup.configuration.canBeReplacedByHigherPriority = false
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.clearAllQueues()
        _ = manager.requestShow(
            popup: popup,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: {}
        )
        XCTAssertTrue(popup.configuration.canBeReplacedByHigherPriority)
        manager.clearAllQueues()
    }

    func testDuplicatePopupCannotEnterQueueTwice() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let popup = TFYSwiftPopupView(frame: .zero)

        XCTAssertTrue(manager.requestShow(
            popup: popup,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: {}
        ))
        XCTAssertFalse(manager.requestShow(
            popup: popup,
            priority: .normal,
            strategy: .queue,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: {}
        ))
        XCTAssertEqual(manager.totalQueueCount(), 1)
    }

    func testQueuedPopupIsRetainedUntilItLeavesQueue() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let blocker = TFYSwiftPopupView(frame: .zero)
        XCTAssertTrue(manager.requestShow(
            popup: blocker,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: false,
            showBlock: {}
        ))

        weak var queuedReference: TFYSwiftPopupView?
        autoreleasepool {
            let queued = TFYSwiftPopupView(frame: .zero)
            queuedReference = queued
            XCTAssertTrue(manager.requestShow(
                popup: queued,
                priority: .normal,
                strategy: .queue,
                maxWaitingTime: 0,
                canBeReplaced: false,
                showBlock: {}
            ))
        }

        XCTAssertNotNil(queuedReference)
        XCTAssertTrue(manager.waitingQueue().contains { $0.popupView === queuedReference })
    }

    func testWaitingQueueSortsByPriorityAndPreservesFIFO() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let blocker = TFYSwiftPopupView(frame: .zero)
        let firstLow = TFYSwiftPopupView(frame: .zero)
        let urgent = TFYSwiftPopupView(frame: .zero)
        let secondLow = TFYSwiftPopupView(frame: .zero)
        XCTAssertTrue(manager.requestShow(
            popup: blocker,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: false,
            showBlock: {}
        ))

        for (popup, priority) in [(firstLow, TFYPopupPriority.low), (urgent, .urgent), (secondLow, .low)] {
            XCTAssertTrue(manager.requestShow(
                popup: popup,
                priority: priority,
                strategy: .queue,
                maxWaitingTime: 0,
                canBeReplaced: false,
                showBlock: {}
            ))
        }

        let waiting = manager.waitingQueue()
        XCTAssertEqual(waiting.count, 3)
        XCTAssertTrue(waiting[0].popupView === urgent)
        XCTAssertTrue(waiting[1].popupView === firstLow)
        XCTAssertTrue(waiting[2].popupView === secondLow)
    }

    func testWaitingTimeoutDoesNotUntrackPopupAfterItStartsShowing() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let blocker = TFYSwiftPopupView(frame: .zero)
        let queued = TFYSwiftPopupView(frame: .zero)
        XCTAssertTrue(manager.requestShow(
            popup: blocker,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: false,
            showBlock: {}
        ))
        XCTAssertTrue(manager.requestShow(
            popup: queued,
            priority: .normal,
            strategy: .queue,
            maxWaitingTime: 0.05,
            canBeReplaced: false,
            showBlock: {}
        ))

        manager.remove(popup: blocker)
        XCTAssertTrue(manager.currentDisplayedPopups().contains { $0 === queued })

        let timeoutPassed = expectation(description: "waiting timeout passed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { timeoutPassed.fulfill() }
        wait(for: [timeoutPassed], timeout: 1)
        XCTAssertTrue(manager.currentDisplayedPopups().contains { $0 === queued })
    }

    func testAutomaticExpiryCleanupCanBeDisabled() {
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.autoCleanupExpiredPopups = false
        let blocker = TFYSwiftPopupView(frame: .zero)
        let queued = TFYSwiftPopupView(frame: .zero)
        XCTAssertTrue(manager.requestShow(
            popup: blocker,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: false,
            showBlock: {}
        ))
        XCTAssertTrue(manager.requestShow(
            popup: queued,
            priority: .normal,
            strategy: .queue,
            maxWaitingTime: 0.01,
            canBeReplaced: false,
            showBlock: {}
        ))

        let timeoutPassed = expectation(description: "waiting item expired")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { timeoutPassed.fulfill() }
        wait(for: [timeoutPassed], timeout: 1)
        XCTAssertTrue(manager.waitingQueue().contains { $0.popupView === queued })

        let queueUpdated = expectation(forNotification: .tfyPopupQueueDidUpdate, object: manager)
        manager.clearExpiredWaitingPopups()
        wait(for: [queueUpdated], timeout: 1)
        XCTAssertFalse(manager.waitingQueue().contains { $0.popupView === queued })
    }

    func testPopupsWithPriorityIncludesDisplayedAndWaitingItems() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let displayed = TFYSwiftPopupView(frame: .zero)
        let waiting = TFYSwiftPopupView(frame: .zero)
        XCTAssertTrue(manager.requestShow(
            popup: displayed,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: false,
            showBlock: {}
        ))
        XCTAssertTrue(manager.requestShow(
            popup: waiting,
            priority: .normal,
            strategy: .queue,
            maxWaitingTime: 0,
            canBeReplaced: false,
            showBlock: {}
        ))

        let popups = manager.popups(withPriority: .normal)
        XCTAssertEqual(popups.count, 2)
        XCTAssertTrue(popups.contains { $0 === displayed })
        XCTAssertTrue(popups.contains { $0 === waiting })
    }

    func testReplaceStrategyFreesCapacityForIncomingPopup() {
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.enforceMaxPopupCount(1)
        let existing = TFYSwiftPopupView(frame: .zero)
        let incoming = TFYSwiftPopupView(frame: .zero)
        XCTAssertTrue(manager.requestShow(
            popup: existing,
            priority: .low,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: {}
        ))

        XCTAssertTrue(manager.requestShow(
            popup: incoming,
            priority: .urgent,
            strategy: .replace,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: {}
        ))
        XCTAssertEqual(manager.currentDisplayedPopups().count, 1)
        XCTAssertTrue(manager.currentDisplayedPopups().first === incoming)
    }

    func testRejectStrategyDoesNotSilentlyQueue() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let existing = TFYSwiftPopupView(frame: .zero)
        let incoming = TFYSwiftPopupView(frame: .zero)

        XCTAssertTrue(manager.requestShow(
            popup: existing,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: false,
            showBlock: {}
        ))
        XCTAssertFalse(manager.requestShow(
            popup: incoming,
            priority: .urgent,
            strategy: .reject,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: {}
        ))
        XCTAssertFalse(manager.waitingQueue().contains { $0.popupView === incoming })
    }

    func testHighestPriorityIncludesDisplayedPopup() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let popup = TFYSwiftPopupView(frame: .zero)
        _ = manager.requestShow(
            popup: popup,
            priority: .critical,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: {}
        )
        XCTAssertEqual(manager.currentHighestPriority(), .critical)
    }

    func testRemovingScheduledPopupCancelsItsShowBlock() {
        let manager = TFYSwiftPopupPriorityManager.shared
        let popup = TFYSwiftPopupView(frame: .zero)
        var didShow = false

        XCTAssertTrue(manager.requestShow(
            popup: popup,
            priority: .normal,
            strategy: .overlay,
            maxWaitingTime: 0,
            canBeReplaced: true,
            showBlock: { didShow = true }
        ))
        manager.remove(popup: popup)

        let drainedMainQueue = expectation(description: "main queue drained")
        DispatchQueue.main.async { drainedMainQueue.fulfill() }
        wait(for: [drainedMainQueue], timeout: 1)
        XCTAssertFalse(didShow)
    }
}

final class TFYSwiftPopupLayoutTests: XCTestCase {

    private final class DeferredDismissAnimator: TFYSwiftPopupViewAnimator {
        private var dismissal: (() -> Void)?

        func setup(popupView: TFYSwiftPopupView, contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView) {}
        func refreshLayout(popupView: TFYSwiftPopupView, contentView: UIView) {}
        func display(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void) {
            completion()
        }
        func dismiss(contentView: UIView, backgroundView: TFYSwiftPopupBackgroundView, animated: Bool, completion: @escaping () -> Void) {
            dismissal = completion
        }
        func finishDismissal() { dismissal?() }
    }

    func testKeyboardAvoidanceUsesActualOverlap() {
        let offset = TFYSwiftPopupLayoutHelper.keyboardAvoidanceOffset(
            popupFrame: CGRect(x: 100, y: 100, width: 300, height: 300),
            keyboardFrame: CGRect(x: 0, y: 350, width: 600, height: 300),
            additionalOffset: 10,
            safeAreaBottom: 34
        )
        XCTAssertEqual(offset, 26)
    }

    func testKeyboardAvoidanceIgnoresNonOverlappingFloatingKeyboard() {
        let offset = TFYSwiftPopupLayoutHelper.keyboardAvoidanceOffset(
            popupFrame: CGRect(x: 0, y: 100, width: 200, height: 200),
            keyboardFrame: CGRect(x: 300, y: 200, width: 200, height: 200),
            additionalOffset: 10,
            safeAreaBottom: 0
        )
        XCTAssertEqual(offset, 0)
    }

    func testPopupCanBeReusedAfterDismissal() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let popup = TFYSwiftPopupView(frame: .zero)
        let layout = TFYSwiftPopupAnimatorLayout.center(
            .layout(offsetY: 0, offsetX: 0, width: 240, height: 180)
        )

        let flip = TFYSwiftPopup3DFlipAnimator()
        flip.layout = layout
        popup.show(in: container, animator: flip, animated: false)
        XCTAssertTrue(popup.isShowing)
        popup.dismissAnimated(false)
        XCTAssertFalse(popup.isShowing)
        XCTAssertNil(popup.superview)

        let fade = TFYSwiftPopupFadeInOutAnimator()
        fade.layout = layout
        popup.show(in: container, animator: fade, animated: false)
        XCTAssertTrue(popup.isShowing)
        XCTAssertEqual(popup.alpha, 1)
        XCTAssertTrue(CATransform3DEqualToTransform(popup.layer.transform, CATransform3DIdentity))
        popup.dismissAnimated(false)
    }

    func testRepeatedDismissCompletionsWaitForActualDismissal() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let popup = TFYSwiftPopupView(frame: .zero)
        let animator = DeferredDismissAnimator()
        popup.show(in: container, animator: animator, animated: false)

        var completions = 0
        popup.dismissAnimated(true) { completions += 1 }
        popup.dismissAnimated(true) { completions += 1 }
        XCTAssertEqual(completions, 0)

        animator.finishDismissal()
        XCTAssertEqual(completions, 2)
        XCTAssertFalse(popup.isShowing)
    }

    func testBottomSheetUsesContainerHeightWhenMaximumIsAutomatic() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 600))
        let popup = TFYSwiftPopupView(frame: .zero)
        let config = TFYSwiftPopupBottomSheetConfiguration()
        config.defaultHeight = 300
        config.minimumHeight = 100
        config.maximumHeight = 0
        let animator = TFYSwiftPopupBottomSheetAnimator(configuration: config)

        popup.show(in: container, animator: animator, animated: false)
        let heightConstraints = popup.constraints.filter {
            $0.firstItem === popup && $0.firstAttribute == .height
        }
        XCTAssertTrue(heightConstraints.contains { $0.relation == .equal && $0.constant == 300 })
        XCTAssertTrue(heightConstraints.contains { $0.relation == .greaterThanOrEqual && $0.constant == 100 })
        XCTAssertTrue(heightConstraints.contains { $0.relation == .lessThanOrEqual && $0.constant == 600 })
        popup.dismissAnimated(false)
    }

    func testFullHeightLeadingLayoutDoesNotAlsoConstrainCenterY() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let popup = TFYSwiftPopupView(frame: .zero)
        let animator = TFYSwiftPopupSlideAnimator(
            direction: .fromLeft,
            layout: .leading(.layout(leadingMargin: 0, offsetY: 0, width: 280))
        )

        popup.show(in: container, animator: animator, animated: false)
        let popupConstraints = container.constraints.filter {
            $0.firstItem === popup || $0.secondItem === popup
        }
        XCTAssertTrue(popupConstraints.contains { $0.firstAttribute == .top || $0.secondAttribute == .top })
        XCTAssertTrue(popupConstraints.contains { $0.firstAttribute == .bottom || $0.secondAttribute == .bottom })
        XCTAssertFalse(popupConstraints.contains { $0.firstAttribute == .centerY || $0.secondAttribute == .centerY })
        popup.dismissAnimated(false)
    }
}

final class TFYSwiftPopupContainerTests: XCTestCase {

    func testAvailabilityTracksWindowAttachmentAndVisibility() {
        let view = UIView(frame: .zero)
        let info = TFYSwiftPopupContainerInfo.viewContainer(view, name: "dynamic")
        XCTAssertFalse(info.isAvailable)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.isHidden = false
        window.addSubview(view)
        XCTAssertTrue(info.isAvailable)

        window.isHidden = true
        XCTAssertFalse(info.isAvailable)
    }
}

final class TFYSwiftPanModalHeightTests: XCTestCase {

    private final class DetachedScrollableViewController: UIViewController {
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        override func panScrollable() -> UIScrollView? { scrollView }
    }

    func testTopMarginHelper() {
        let content = TFYSwiftPanModalLayoutHelper.topMargin(
            for: PanModalHeight(type: .content, height: 200),
            bottomYPos: 800,
            bottomLayoutOffset: 34,
            intrinsicHeightProvider: nil
        )
        XCTAssertEqual(content, 800 - 200 - 34)

        let maxMargin = TFYSwiftPanModalLayoutHelper.topMargin(
            for: PanModalHeight(type: .max, height: 0),
            bottomYPos: 800,
            bottomLayoutOffset: 0,
            intrinsicHeightProvider: nil
        )
        XCTAssertEqual(maxMargin, 0)
    }

    func testTopMarginClampsInvalidAndOversizedHeights() {
        let oversized = TFYSwiftPanModalLayoutHelper.topMargin(
            for: PanModalHeight(type: .content, height: 1_000),
            bottomYPos: 800,
            bottomLayoutOffset: 34,
            intrinsicHeightProvider: nil
        )
        XCTAssertEqual(oversized, 0)

        let invalid = TFYSwiftPanModalLayoutHelper.topMargin(
            for: PanModalHeight(type: .topInset, height: .infinity),
            bottomYPos: 800,
            bottomLayoutOffset: 0,
            intrinsicHeightProvider: nil
        )
        XCTAssertEqual(invalid, 0)
    }

    func testFloatHelpers() {
        XCTAssertTrue(CGFloat(0).isNearZero)
        XCTAssertTrue(CGFloat(1.0).isNearlyEqual(to: 1.00005))
        XCTAssertFalse(CGFloat(1.0).isNearlyEqual(to: 2.0))
    }

    func testExtendedScrollingDoesNotInspectDetachedScrollView() {
        let viewController = DetachedScrollableViewController()
        viewController.scrollView.contentSize.height = 1_000
        XCTAssertFalse(viewController.allowsExtendedPanScrolling())
    }
}

final class TFYSwiftKeyboardModeTests: XCTestCase {

    func testKeyboardConfigValidate() {
        let config = TFYSwiftPopupKeyboardConfiguration()
        XCTAssertTrue(config.validate())
        config.animationDuration = -1
        XCTAssertFalse(config.validate())
    }

    func testAvoidingModesExist() {
        XCTAssertEqual(TFYPopupKeyboardAvoidingMode.transform.rawValue, 0)
        XCTAssertEqual(TFYPopupKeyboardAvoidingMode.constraint.rawValue, 1)
        XCTAssertEqual(TFYPopupKeyboardAvoidingMode.resize.rawValue, 2)
    }
}

final class TFYSwiftBottomSheetConfigurationTests: XCTestCase {

    func testValidationAndAutomaticMaximumHeight() {
        let config = TFYSwiftPopupBottomSheetConfiguration()
        XCTAssertEqual(config.maximumHeight, 0)
        XCTAssertTrue(config.validate())

        config.springDamping = 1.1
        XCTAssertFalse(config.validate())
        config.springDamping = 0.8
        config.minimumHeight = 400
        config.maximumHeight = 300
        XCTAssertFalse(config.validate())
    }
}

final class TFYSwiftPopupPresentableTests: XCTestCase {

    func testDefaultPreferredSize() {
        let vc = UIViewController()
        let size = vc.popupPreferredContentSize()
        XCTAssertEqual(size.width, 300)
        XCTAssertEqual(size.height, 220)
    }

    func testPreferredContentSizeOverride() {
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 280, height: 180)
        let size = vc.popupPreferredContentSize()
        XCTAssertEqual(size.width, 280)
        XCTAssertEqual(size.height, 180)
    }

    func testContentViewControllerOverrides() {
        let vc = TFYSwiftPopupContentViewController()
        let config = vc.preferredPopupConfiguration()
        XCTAssertEqual(config.cornerRadius, 16)
        XCTAssertTrue(vc.shouldAllowPopupDismiss())
        XCTAssertNil(vc.preferredPopupAnimator())
    }

    func testHostingViewHoldsContent() {
        let content = UIViewController()
        let hosting = TFYSwiftPopupHostingView(contentViewController: content)
        XCTAssertTrue(hosting.contentViewController === content)
    }
}
