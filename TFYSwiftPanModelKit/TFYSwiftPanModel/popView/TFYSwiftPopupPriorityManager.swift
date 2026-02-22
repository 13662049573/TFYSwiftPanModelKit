//
//  TFYSwiftPopupPriorityManager.swift
//  TFYSwiftPanModel
//
//  弹窗优先级管理器，由 OC TFYPopupPriorityManager 迁移。
//

import UIKit

/// 弹窗优先级
public enum TFYPopupPriority: Int {
    case background = 0
    case low = 100
    case normal = 200
    case high = 300
    case critical = 400
    case urgent = 500
}

/// 优先级处理策略
public enum TFYPopupPriorityStrategy: UInt {
    case queue = 0
    case replace
    case overlay
    case reject
}

/// 优先级队列项
public final class TFYSwiftPopupPriorityItem: NSObject {
    public weak var popupView: TFYSwiftPopupView?
    public let priority: TFYPopupPriority
    public let strategy: TFYPopupPriorityStrategy
    public let enqueuedTime: Date
    public let maxWaitingTime: TimeInterval
    public var completionBlock: (() -> Void)?

    public init(popupView: TFYSwiftPopupView, priority: TFYPopupPriority, strategy: TFYPopupPriorityStrategy, maxWaitingTime: TimeInterval, completion: (() -> Void)?) {
        self.popupView = popupView
        self.priority = priority
        self.strategy = strategy
        self.enqueuedTime = Date()
        self.maxWaitingTime = maxWaitingTime
        self.completionBlock = completion
        super.init()
    }

    public var isExpired: Bool {
        maxWaitingTime <= 0 ? false : Date().timeIntervalSince(enqueuedTime) > maxWaitingTime
    }
}

// 通知名
public extension Notification.Name {
    static let tfyPopupPriorityDidChange = Notification.Name("TFYPopupPriorityDidChangeNotification")
    static let tfyPopupQueueDidUpdate = Notification.Name("TFYPopupQueueDidUpdateNotification")
    static let tfyPopupDidReplace = Notification.Name("TFYPopupDidReplaceNotification")
}

// MARK: - TFYPopupPriority Extension

public extension TFYPopupPriority {
    /// 比较两个优先级
    static func isHigher(_ p1: TFYPopupPriority, than p2: TFYPopupPriority) -> Bool {
        p1.rawValue > p2.rawValue
    }

    /// 获取优先级数值
    static func value(from priority: TFYPopupPriority) -> Int {
        priority.rawValue
    }

    /// 从数值创建优先级（取最接近的枚举值）
    static func fromValue(_ value: Int) -> TFYPopupPriority {
        let raw = max(TFYPopupPriority.background.rawValue, min(TFYPopupPriority.urgent.rawValue, value))
        if let p = TFYPopupPriority(rawValue: raw) { return p }
        let cases: [TFYPopupPriority] = [.background, .low, .normal, .high, .critical, .urgent]
        return cases.min(by: { abs($0.rawValue - raw) < abs($1.rawValue - raw) }) ?? .normal
    }
}

/// 比较两个优先级
@available(*, deprecated, renamed: "TFYPopupPriority.isHigher(than:)")
public func TFYPopupPriorityIsHigher(_ p1: TFYPopupPriority, _ p2: TFYPopupPriority) -> Bool {
    TFYPopupPriority.isHigher(p1, than: p2)
}

/// 获取优先级数值
@available(*, deprecated, renamed: "TFYPopupPriority.value(from:)")
public func TFYPopupPriorityGetValue(_ priority: TFYPopupPriority) -> Int {
    TFYPopupPriority.value(from: priority)
}

/// 从数值创建优先级（取最接近的枚举值）
@available(*, deprecated, renamed: "TFYPopupPriority.fromValue(_:)")
public func TFYPopupPriorityFromValue(_ value: Int) -> TFYPopupPriority {
    TFYPopupPriority.fromValue(value)
}

/// 优先级管理器
public final class TFYSwiftPopupPriorityManager: NSObject {
    public static let shared = TFYSwiftPopupPriorityManager()
    public var defaultMaxWaitingTime: TimeInterval = 30
    public var maxSimultaneousPopups: Int = 1
    public var autoCleanupExpiredPopups = true
    private var _isQueuePaused = false
    public var isQueuePaused: Bool {
        queue.sync { _isQueuePaused }
    }

    private var displayedPopups: [TFYSwiftPopupView] = []
    private var internalWaitingQueue: [TFYSwiftPopupPriorityItem] = []
    private let queue = DispatchQueue(label: "com.tfy.popup.priority.queue", attributes: .concurrent)

    private override init() {
        super.init()
    }

    @discardableResult
    public func add(popup: TFYSwiftPopupView, priority: TFYPopupPriority, strategy: TFYPopupPriorityStrategy, completion: (() -> Void)?) -> Bool {
        queue.sync(flags: .barrier) {
            let item = TFYSwiftPopupPriorityItem(popupView: popup, priority: priority, strategy: strategy, maxWaitingTime: defaultMaxWaitingTime, completion: completion)
            internalWaitingQueue.append(item)
            internalWaitingQueue.sort { TFYPopupPriority.isHigher($0.priority, than: $1.priority) }
        }
        NotificationCenter.default.post(name: .tfyPopupQueueDidUpdate, object: self)
        processNext()
        return true
    }

    public func remove(popup: TFYSwiftPopupView) {
        queue.sync(flags: .barrier) {
            displayedPopups.removeAll { $0 === popup }
            internalWaitingQueue.removeAll { $0.popupView === popup }
        }
        processNext()
    }

    public func processNext() {
        queue.sync(flags: .barrier) {
            guard !_isQueuePaused, displayedPopups.count < maxSimultaneousPopups else { return }
            guard let next = internalWaitingQueue.first(where: { !$0.isExpired }), let popup = next.popupView else { return }
            internalWaitingQueue.removeAll { $0 === next }
            displayedPopups.append(popup)
            next.completionBlock?()
        }
    }

    public func currentHighestPriority() -> TFYPopupPriority {
        queue.sync {
            guard !internalWaitingQueue.isEmpty else {
                return displayedPopups.isEmpty ? .background : .normal
            }
            let maxRawValue = internalWaitingQueue.map { $0.priority.rawValue }.max() ?? TFYPopupPriority.normal.rawValue
            return TFYPopupPriority.fromValue(maxRawValue)
        }
    }

    public func popups(withPriority priority: TFYPopupPriority) -> [TFYSwiftPopupView] {
        queue.sync {
            let items = internalWaitingQueue.filter { $0.priority == priority }
            return items.compactMap { $0.popupView }
        }
    }

    public func currentDisplayedPopups() -> [TFYSwiftPopupView] {
        queue.sync { displayedPopups }
    }

    public func waitingQueue() -> [TFYSwiftPopupPriorityItem] {
        queue.sync { internalWaitingQueue }
    }

    public func totalQueueCount() -> Int {
        queue.sync { displayedPopups.count + internalWaitingQueue.count }
    }

    public func clearPopups(withPriorityLowerThan priority: TFYPopupPriority) {
        queue.sync(flags: .barrier) {
            internalWaitingQueue.removeAll { TFYPopupPriority.value(from: $0.priority) < priority.rawValue }
        }
    }

    public func clearExpiredWaitingPopups() {
        queue.sync(flags: .barrier) {
            internalWaitingQueue.removeAll { $0.isExpired }
        }
    }

    public func pauseQueue() {
        queue.sync(flags: .barrier) { _isQueuePaused = true }
    }

    public func resumeQueue() {
        queue.sync(flags: .barrier) { _isQueuePaused = false }
        processNext()
    }

    public func clearAllQueues() {
        queue.sync(flags: .barrier) {
            displayedPopups.removeAll()
            internalWaitingQueue.removeAll()
        }
    }

    public static func enablePriorityDebugMode(_ enabled: Bool) {}
    public static func isPriorityDebugModeEnabled() -> Bool { false }
    public func logPriorityQueue() {}
    public static func priorityDescription(_ priority: TFYPopupPriority) -> String { "\(priority.rawValue)" }
    public static func strategyDescription(_ strategy: TFYPopupPriorityStrategy) -> String { "\(strategy.rawValue)" }
}
