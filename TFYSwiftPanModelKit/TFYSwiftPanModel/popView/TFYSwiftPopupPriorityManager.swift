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
    /// 队列总容量上限（展示中 + 等待）；0 表示不限制
    public var maxPopupCount: Int = 0
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
        popup.configuration.priority = priority
        let added = queue.sync(flags: .barrier) { () -> Bool in
            guard !containsPopupLocked(popup) else { return false }
            if maxPopupCount > 0,
               displayedPopups.count + internalWaitingQueue.count >= maxPopupCount {
                return false
            }
            let item = TFYSwiftPopupPriorityItem(
                popupView: popup,
                priority: priority,
                strategy: strategy,
                maxWaitingTime: defaultMaxWaitingTime,
                completion: completion
            )
            internalWaitingQueue.append(item)
            internalWaitingQueue.sort { TFYPopupPriority.isHigher($0.priority, than: $1.priority) }
            return true
        }
        guard added else { return false }
        NotificationCenter.default.post(name: .tfyPopupQueueDidUpdate, object: self)
        processNext()
        return true
    }

    /// 设置队列总容量上限（展示中 + 等待中）
    public func enforceMaxPopupCount(_ count: Int) {
        queue.sync(flags: .barrier) {
            maxPopupCount = max(0, count)
        }
    }

    /// 根据策略请求展示弹窗
    @discardableResult
    public func requestShow(
        popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        strategy: TFYPopupPriorityStrategy,
        maxWaitingTime: TimeInterval,
        canBeReplaced: Bool,
        showBlock: @escaping () -> Void
    ) -> Bool {
        // Store replaceability on the popup's configuration for later lookup
        popup.configuration.priority = priority
        popup.configuration.canBeReplacedByHigherPriority = canBeReplaced
        let isAlreadyTracked = queue.sync { containsPopupLocked(popup) }
        guard !isAlreadyTracked else { return false }

        let simultaneousLimit = max(1, maxSimultaneousPopups)

        switch strategy {
        case .reject:
            let decision = queue.sync { () -> (hasCapacity: Bool, toReplace: [TFYSwiftPopupView]) in
                guard displayedPopups.count >= simultaneousLimit else {
                    return (true, [])
                }
                let replaceable = displayedPopups.filter {
                    $0.configuration.canBeReplacedByHigherPriority
                        && TFYPopupPriority.isHigher(priority, than: popupPriority(for: $0))
                }
                return (false, replaceable)
            }
            if decision.hasCapacity {
                return executeShow(popup: popup, showBlock: showBlock)
            }
            if !decision.toReplace.isEmpty {
                dismissDisplayed(decision.toReplace)
                return executeShow(popup: popup, showBlock: showBlock)
            }
            return false

        case .replace:
            let toDismiss = queue.sync { displayedPopups }
            dismissDisplayed(toDismiss)
            return executeShow(popup: popup, showBlock: showBlock)

        case .overlay:
            return executeShow(popup: popup, showBlock: showBlock)

        case .queue:
            let decision = queue.sync { () -> (hasCapacity: Bool, replaceable: [TFYSwiftPopupView]) in
                guard displayedPopups.count >= simultaneousLimit else { return (true, []) }
                let replaceable = displayedPopups.filter {
                    $0.configuration.canBeReplacedByHigherPriority
                        && TFYPopupPriority.isHigher(priority, than: popupPriority(for: $0))
                }
                return (false, replaceable)
            }
            if decision.hasCapacity {
                return executeShow(popup: popup, showBlock: showBlock)
            }
            if !decision.replaceable.isEmpty {
                dismissDisplayed(decision.replaceable)
                return executeShow(popup: popup, showBlock: showBlock)
            }
            return enqueue(popup: popup, priority: priority, strategy: strategy, maxWaitingTime: maxWaitingTime, showBlock: showBlock)
        }
    }

    private func dismissDisplayed(_ popups: [TFYSwiftPopupView]) {
        queue.sync(flags: .barrier) {
            for popup in popups {
                displayedPopups.removeAll { $0 === popup }
            }
        }
        DispatchQueue.main.async {
            popups.forEach { $0.dismissAnimated(false, force: true) }
        }
        if !popups.isEmpty {
            NotificationCenter.default.post(name: .tfyPopupDidReplace, object: self)
        }
    }

    public func popupPriority(for popup: TFYSwiftPopupView) -> TFYPopupPriority {
        popup.configuration.priority
    }

    public func remove(popup: TFYSwiftPopupView) {
        let didRemove = queue.sync(flags: .barrier) { () -> Bool in
            let oldCount = displayedPopups.count + internalWaitingQueue.count
            displayedPopups.removeAll { $0 === popup }
            internalWaitingQueue.removeAll { $0.popupView === popup }
            return oldCount != displayedPopups.count + internalWaitingQueue.count
        }
        if didRemove {
            NotificationCenter.default.post(name: .tfyPopupQueueDidUpdate, object: self)
        }
        processNext()
    }

    public func processNext() {
        queue.sync(flags: .barrier) {
            guard !_isQueuePaused else { return }
            clearExpiredWaitingPopupsInternal()
            let simultaneousLimit = max(1, maxSimultaneousPopups)
            while displayedPopups.count < simultaneousLimit,
                  let nextIndex = internalWaitingQueue.firstIndex(where: { !$0.isExpired && $0.popupView != nil }),
                  let popup = internalWaitingQueue[nextIndex].popupView {
                let item = internalWaitingQueue.remove(at: nextIndex)
                guard !displayedPopups.contains(where: { $0 === popup }) else { continue }
                displayedPopups.append(popup)
                DispatchQueue.main.async { [weak self, weak popup] in
                    item.completionBlock?()
                    // show 异步完成后若仍未展示，释放槽位，避免后续弹窗永久等待
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        guard let self, let popup else { return }
                        if !popup.isShowing {
                            self.remove(popup: popup)
                        }
                    }
                }
            }
        }
    }

    public func currentHighestPriority() -> TFYPopupPriority {
        queue.sync {
            let waitingPriorities = internalWaitingQueue
                .filter { !$0.isExpired && $0.popupView != nil }
                .map { $0.priority.rawValue }
            let displayedPriorities = displayedPopups.map { popupPriority(for: $0).rawValue }
            let maxRawValue = (waitingPriorities + displayedPriorities).max() ?? TFYPopupPriority.background.rawValue
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
        NotificationCenter.default.post(name: .tfyPopupQueueDidUpdate, object: self)
    }

    public func clearExpiredWaitingPopups() {
        queue.sync(flags: .barrier) {
            clearExpiredWaitingPopupsInternal()
        }
        processNext()
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
        NotificationCenter.default.post(name: .tfyPopupQueueDidUpdate, object: self)
    }

    public static func enablePriorityDebugMode(_ enabled: Bool) {
        TFYSwiftPopupPriorityManager.shared._debugEnabled = enabled
    }

    public static func isPriorityDebugModeEnabled() -> Bool {
        TFYSwiftPopupPriorityManager.shared._debugEnabled
    }

    public func logPriorityQueue() {
        guard _debugEnabled else { return }
        let waiting = waitingQueue().count
        let displayed = currentDisplayedPopups().count
        print("[TFYPopupPriority] displayed=\(displayed) waiting=\(waiting) paused=\(isQueuePaused)")
    }

    public static func priorityDescription(_ priority: TFYPopupPriority) -> String {
        switch priority {
        case .background: return "Background"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        case .urgent: return "Urgent"
        }
    }

    public static func strategyDescription(_ strategy: TFYPopupPriorityStrategy) -> String {
        switch strategy {
        case .queue: return "Queue"
        case .replace: return "Replace"
        case .overlay: return "Overlay"
        case .reject: return "Reject"
        }
    }

    // MARK: - Private

    fileprivate var _debugEnabled = false

    @discardableResult
    private func enqueue(
        popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        strategy: TFYPopupPriorityStrategy,
        maxWaitingTime: TimeInterval,
        showBlock: @escaping () -> Void
    ) -> Bool {
        let waitingTime = max(0, maxWaitingTime > 0 ? maxWaitingTime : defaultMaxWaitingTime)
        let item = TFYSwiftPopupPriorityItem(
            popupView: popup,
            priority: priority,
            strategy: strategy,
            maxWaitingTime: waitingTime,
            completion: { [weak self] in
                self?.logPriorityQueue()
                showBlock()
            }
        )
        let canEnqueue = queue.sync(flags: .barrier) { () -> Bool in
            guard !containsPopupLocked(popup) else { return false }
            if maxPopupCount > 0,
               displayedPopups.count + internalWaitingQueue.count >= maxPopupCount {
                return false
            }
            internalWaitingQueue.append(item)
            internalWaitingQueue.sort { TFYPopupPriority.isHigher($0.priority, than: $1.priority) }
            return true
        }
        guard canEnqueue else { return false }

        NotificationCenter.default.post(name: .tfyPopupQueueDidUpdate, object: self)
        processNext()
        if waitingTime > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + waitingTime) { [weak self, weak popup] in
                guard let self, let popup, item.isExpired else { return }
                self.remove(popup: popup)
            }
        }
        return true
    }

    @discardableResult
    private func executeShow(popup: TFYSwiftPopupView, showBlock: @escaping () -> Void) -> Bool {
        let accepted = queue.sync(flags: .barrier) { () -> Bool in
            guard !containsPopupLocked(popup) else { return false }
            if maxPopupCount > 0,
               displayedPopups.count + internalWaitingQueue.count >= maxPopupCount {
                return false
            }
            displayedPopups.append(popup)
            return true
        }
        guard accepted else { return false }
        DispatchQueue.main.async { [weak self, weak popup] in
            showBlock()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard let self, let popup else { return }
                if !popup.isShowing {
                    self.remove(popup: popup)
                }
            }
        }
        logPriorityQueue()
        return true
    }

    private func containsPopupLocked(_ popup: TFYSwiftPopupView) -> Bool {
        displayedPopups.contains { $0 === popup }
            || internalWaitingQueue.contains { $0.popupView === popup }
    }

    private func clearExpiredWaitingPopupsInternal() {
        internalWaitingQueue.removeAll { $0.isExpired || $0.popupView == nil }
    }
}
