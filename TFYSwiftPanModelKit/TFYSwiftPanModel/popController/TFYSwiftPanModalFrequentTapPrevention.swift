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
    public var preventionInterval: TimeInterval = 1 {
        didSet {
            if preventionInterval < 0 {
                preventionInterval = 0
            }
        }
    }
    public var shouldShowHint: Bool = false
    public var hintText: String?

    public private(set) var isPrevented: Bool = false
    public private(set) var remainingTime: TimeInterval = 0

    private var lastTriggerTime: TimeInterval = 0
    private var resetWorkItem: DispatchWorkItem?

    public init(preventionInterval interval: TimeInterval) {
        preventionInterval = max(0, interval)
    }

    public static func prevention(withInterval interval: TimeInterval) -> TFYSwiftPanModalFrequentTapPrevention {
        TFYSwiftPanModalFrequentTapPrevention(preventionInterval: interval)
    }

    public func canExecute() -> Bool {
        guard enabled else { return true }
        return preventionInterval <= 0 || CACurrentMediaTime() - lastTriggerTime >= preventionInterval
    }

    @discardableResult
    public func executeIfAllowed(block: () -> Void) -> Bool {
        guard canExecute() else { return false }
        block()
        triggerPrevention()
        return true
    }

    public func triggerPrevention() {
        resetWorkItem?.cancel()
        guard enabled, preventionInterval > 0 else {
            reset(notifyDelegate: false)
            return
        }

        lastTriggerTime = CACurrentMediaTime()
        isPrevented = true
        remainingTime = preventionInterval
        delegate?.frequentTapPreventionStateChanged(isPrevented: true, remainingTime: remainingTime)

        let workItem = DispatchWorkItem { [weak self] in
            self?.reset()
        }
        resetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + preventionInterval, execute: workItem)
    }

    public func reset() {
        reset(notifyDelegate: true)
    }

    private func reset(notifyDelegate: Bool) {
        resetWorkItem?.cancel()
        resetWorkItem = nil
        let wasPrevented = isPrevented
        isPrevented = false
        remainingTime = 0
        if notifyDelegate, wasPrevented {
            delegate?.frequentTapPreventionStateChanged(isPrevented: false, remainingTime: 0)
        }
    }

    public var currentRemainingTime: TimeInterval {
        guard isPrevented else { return 0 }
        let elapsed = CACurrentMediaTime() - lastTriggerTime
        return max(0, preventionInterval - elapsed)
    }

    @available(*, deprecated, renamed: "currentRemainingTime")
    public func getRemainingTime() -> TimeInterval { currentRemainingTime }

    deinit {
        resetWorkItem?.cancel()
    }
}
