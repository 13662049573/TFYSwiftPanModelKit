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
        manager.enforceMaxPopupCount(0)
    }

    override func tearDown() {
        let manager = TFYSwiftPopupPriorityManager.shared
        manager.clearAllQueues()
        manager.maxSimultaneousPopups = 1
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
}

final class TFYSwiftPopupLayoutTests: XCTestCase {

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
}

final class TFYSwiftPanModalHeightTests: XCTestCase {

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
