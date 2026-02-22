//
//  TFYSwiftPanModalFrequentTapPrevention.swift
//  TFYSwiftPanModel
//
//  防频繁点击管理器，由 OC TFYPanModalFrequentTapPrevention 迁移。
//

import UIKit

/// 防频繁点击代理
public protocol TFYSwiftPanModalFrequentTapPreventionDelegate: AnyObject {
    func frequentTapPreventionStateChanged(isPrevented: Bool, remainingTime: TimeInterval)
    func showFrequentTapPreventionHint(_ hintText: String?)
    func hideFrequentTapPreventionHint()
}

public extension TFYSwiftPanModalFrequentTapPreventionDelegate {
    func showFrequentTapPreventionHint(_ hintText: String?) {}
    func hideFrequentTapPreventionHint() {}
}

/// 防频繁点击管理器
public final class TFYSwiftPanModalFrequentTapPrevention {
    public weak var delegate: TFYSwiftPanModalFrequentTapPreventionDelegate?
    public var enabled: Bool = true
    public var preventionInterval: TimeInterval = 1
    public var shouldShowHint: Bool = false
    public var hintText: String?

    public private(set) var isPrevented: Bool = false
    public private(set) var remainingTime: TimeInterval = 0

    private var lastTriggerTime: TimeInterval = 0

    public init(preventionInterval interval: TimeInterval) {
        preventionInterval = interval
    }

    public static func prevention(withInterval interval: TimeInterval) -> TFYSwiftPanModalFrequentTapPrevention {
        TFYSwiftPanModalFrequentTapPrevention(preventionInterval: interval)
    }

    public func canExecute() -> Bool {
        guard enabled else { return true }
        return CACurrentMediaTime() - lastTriggerTime >= preventionInterval
    }

    @discardableResult
    public func executeIfAllowed(block: () -> Void) -> Bool {
        guard canExecute() else { return false }
        block()
        triggerPrevention()
        return true
    }

    public func triggerPrevention() {
        lastTriggerTime = CACurrentMediaTime()
        isPrevented = true
        remainingTime = preventionInterval
        delegate?.frequentTapPreventionStateChanged(isPrevented: true, remainingTime: remainingTime)
    }

    public func reset() {
        isPrevented = false
        remainingTime = 0
        delegate?.frequentTapPreventionStateChanged(isPrevented: false, remainingTime: 0)
    }

    public var currentRemainingTime: TimeInterval {
        guard isPrevented else { return 0 }
        let elapsed = CACurrentMediaTime() - lastTriggerTime
        return max(0, preventionInterval - elapsed)
    }

    @available(*, deprecated, renamed: "currentRemainingTime")
    public func getRemainingTime() -> TimeInterval { currentRemainingTime }
}
