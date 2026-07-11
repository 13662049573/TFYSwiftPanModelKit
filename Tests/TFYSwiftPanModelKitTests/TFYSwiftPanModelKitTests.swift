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
}

final class TFYSwiftPopupPriorityTests: XCTestCase {

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
