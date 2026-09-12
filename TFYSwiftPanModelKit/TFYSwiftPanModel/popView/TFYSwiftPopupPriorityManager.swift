//
//  TFYSwiftPopupPriorityManager.swift
//  TFYSwiftPanModel
//
//  Thread-safe popup priority scheduling.
//

import UIKit

/// 弹窗优先级
public enum TFYPopupPriority: Int, CaseIterable {
    case background = 0
    case low = 100
    case normal = 200
    case high = 300
    case critical = 400
    case urgent = 500
}

/// 优先级处理策略
public enum TFYPopupPriorityStrategy: UInt, CaseIterable {
    /// 无展示槽时按优先级排队；更高优先级可以替换一个允许被替换的低优先级弹窗。
    case queue = 0
    /// 清退当前展示中的弹窗并立即展示新弹窗。
    case replace
    /// 忽略同时展示数量限制直接叠加，但仍遵守队列总容量。
    case overlay
    /// 无展示槽时立即拒绝；仍允许更高优先级替换一个可替换的低优先级弹窗。
    case reject
}

/// 优先级队列项。离开等待队列后 `popupView` 与回调会被释放。
public final class TFYSwiftPopupPriorityItem: NSObject {
    /// 等待期间由队列持有，避免调用方未额外保存时弹窗提前释放。
    public private(set) var popupView: TFYSwiftPopupView?
    public let priority: TFYPopupPriority
    public let strategy: TFYPopupPriorityStrategy
    public let enqueuedTime: Date
    public let maxWaitingTime: TimeInterval
    public let canBeReplacedByHigherPriority: Bool
    public private(set) var completionBlock: (() -> Void)?

    private let enqueuedUptime: TimeInterval
    fileprivate var discardBlock: (() -> Void)?
    fileprivate var expiryWorkItem: DispatchWorkItem?

    public init(
        popupView: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        strategy: TFYPopupPriorityStrategy,
        maxWaitingTime: TimeInterval,
        completion: (() -> Void)?,
        discard: (() -> Void)? = nil,
        canBeReplaced: Bool? = nil
    ) {
        self.popupView = popupView
        self.priority = priority
        self.strategy = strategy
        self.enqueuedTime = Date()
        self.enqueuedUptime = ProcessInfo.processInfo.systemUptime
        self.maxWaitingTime = maxWaitingTime.isFinite ? max(0, maxWaitingTime) : 0
        self.canBeReplacedByHigherPriority = canBeReplaced
            ?? popupView.configuration.canBeReplacedByHigherPriority
        self.completionBlock = completion
        self.discardBlock = discard
        super.init()
    }

    /// 使用单调时钟判断，避免用户修改系统时间导致等待项提前过期或永不过期。
    public var isExpired: Bool {
        maxWaitingTime > 0
            && ProcessInfo.processInfo.systemUptime - enqueuedUptime >= maxWaitingTime
    }

    fileprivate func consumeForDisplay() -> (TFYSwiftPopupView, () -> Void, (() -> Void)?)? {
        guard let popupView, let completionBlock else { return nil }
        expiryWorkItem?.cancel()
        expiryWorkItem = nil
        let discardBlock = discardBlock
        self.popupView = nil
        self.completionBlock = nil
        self.discardBlock = nil
        return (popupView, completionBlock, discardBlock)
    }

    fileprivate func consumeForDiscard() -> (() -> Void)? {
        expiryWorkItem?.cancel()
        expiryWorkItem = nil
        popupView = nil
        completionBlock = nil
        let block = discardBlock
        discardBlock = nil
        return block
    }
}

/// 线程安全的队列状态快照，适合调试面板和监控展示。
public struct TFYSwiftPopupPrioritySnapshot {
    public let displayedPopups: [TFYSwiftPopupView]
    public let waitingItems: [TFYSwiftPopupPriorityItem]
    public let pendingDismissalCount: Int
    public let isPaused: Bool
    public let highestPriority: TFYPopupPriority

    public var displayedCount: Int { displayedPopups.count }
    public var waitingCount: Int { waitingItems.count }
    public var totalCount: Int { displayedCount + waitingCount }
}

// MARK: - Notifications

public extension Notification.Name {
    static let tfyPopupPriorityDidChange = Notification.Name("TFYPopupPriorityDidChangeNotification")
    static let tfyPopupQueueDidUpdate = Notification.Name("TFYPopupQueueDidUpdateNotification")
    static let tfyPopupDidReplace = Notification.Name("TFYPopupDidReplaceNotification")
}

public enum TFYPopupPriorityNotificationKey {
    public static let previousPriority = "previousPriority"
    public static let currentPriority = "currentPriority"
}

// MARK: - TFYPopupPriority Extension

public extension TFYPopupPriority {
    static func isHigher(_ p1: TFYPopupPriority, than p2: TFYPopupPriority) -> Bool {
        p1.rawValue > p2.rawValue
    }

    static func value(from priority: TFYPopupPriority) -> Int {
        priority.rawValue
    }

    /// 从数值创建优先级（取最接近的枚举值）。
    static func fromValue(_ value: Int) -> TFYPopupPriority {
        let raw = max(TFYPopupPriority.background.rawValue, min(TFYPopupPriority.urgent.rawValue, value))
        if let priority = TFYPopupPriority(rawValue: raw) { return priority }
        return allCases.min {
            abs($0.rawValue - raw) < abs($1.rawValue - raw)
        } ?? .normal
    }
}

@available(*, deprecated, renamed: "TFYPopupPriority.isHigher(than:)")
public func TFYPopupPriorityIsHigher(_ p1: TFYPopupPriority, _ p2: TFYPopupPriority) -> Bool {
    TFYPopupPriority.isHigher(p1, than: p2)
}

@available(*, deprecated, renamed: "TFYPopupPriority.value(from:)")
public func TFYPopupPriorityGetValue(_ priority: TFYPopupPriority) -> Int {
    TFYPopupPriority.value(from: priority)
}

@available(*, deprecated, renamed: "TFYPopupPriority.fromValue(_:)")
public func TFYPopupPriorityFromValue(_ value: Int) -> TFYPopupPriority {
    TFYPopupPriority.fromValue(value)
}

/// 优先级管理器。所有状态均由内部串行队列保护；UIKit 回调与通知统一在主线程执行。
public final class TFYSwiftPopupPriorityManager: NSObject {
    public static let shared = TFYSwiftPopupPriorityManager()

    private struct DisplayedMetadata {
        let priority: TFYPopupPriority
        let canBeReplaced: Bool
        var pendingDiscardBlock: (() -> Void)?
    }

    private struct RequestOutcome {
        var isAccepted = false
        var popupToShow: TFYSwiftPopupView?
        var showBlock: (() -> Void)?
        var queuedItem: TFYSwiftPopupPriorityItem?
        var popupsToDismiss: [TFYSwiftPopupView] = []
        var discardBlocks: [() -> Void] = []
        var previousHighestPriority: TFYPopupPriority = .background
        var currentHighestPriority: TFYPopupPriority = .background
    }

    private struct QueueMutation {
        var didChange = false
        var popupsToDismiss: [TFYSwiftPopupView] = []
        var discardBlocks: [() -> Void] = []
        var shows: [(popup: TFYSwiftPopupView, block: () -> Void)] = []
        var previousHighestPriority: TFYPopupPriority = .background
        var currentHighestPriority: TFYPopupPriority = .background
    }

    private let stateQueue = DispatchQueue(label: "com.tfy.popup.priority.state")
    private var displayedPopups: [TFYSwiftPopupView] = []
    private var displayedMetadata: [ObjectIdentifier: DisplayedMetadata] = [:]
    private var internalWaitingQueue: [TFYSwiftPopupPriorityItem] = []
    private var pendingDismissalIDs = Set<ObjectIdentifier>()

    private var _defaultMaxWaitingTime: TimeInterval = 30
    private var _maxSimultaneousPopups = 1
    private var _autoCleanupExpiredPopups = true
    private var _maxPopupCount = 0
    private var _isQueuePaused = false
    private var _debugEnabled = false

    private override init() {
        super.init()
    }

    // MARK: - Thread-safe configuration

    /// 默认等待时间；0 表示永不过期。无效值会被忽略。
    public var defaultMaxWaitingTime: TimeInterval {
        get { stateQueue.sync { _defaultMaxWaitingTime } }
        set {
            guard newValue.isFinite, newValue >= 0 else { return }
            stateQueue.sync { _defaultMaxWaitingTime = newValue }
        }
    }

    /// Queue / Reject 策略允许同时展示的数量，最小值为 1。增大后会立即补位。
    public var maxSimultaneousPopups: Int {
        get { stateQueue.sync { _maxSimultaneousPopups } }
        set {
            let normalized = max(1, newValue)
            let shouldProcess = stateQueue.sync { () -> Bool in
                let oldValue = _maxSimultaneousPopups
                _maxSimultaneousPopups = normalized
                return normalized > oldValue
            }
            if shouldProcess { processNext() }
        }
    }

    public var autoCleanupExpiredPopups: Bool {
        get { stateQueue.sync { _autoCleanupExpiredPopups } }
        set {
            let shouldCleanup = stateQueue.sync { () -> Bool in
                let changed = _autoCleanupExpiredPopups != newValue
                _autoCleanupExpiredPopups = newValue
                return changed && newValue
            }
            if shouldCleanup { clearExpiredWaitingPopups() }
        }
    }

    /// 展示中 + 等待中的总容量；0 表示不限制。
    public var maxPopupCount: Int {
        get { stateQueue.sync { _maxPopupCount } }
        set { enforceMaxPopupCount(newValue) }
    }

    public var isQueuePaused: Bool {
        stateQueue.sync { _isQueuePaused }
    }

    // MARK: - Scheduling

    /// 兼容旧 API：将弹窗加入优先级等待队列，再按可用展示槽自动处理。
    @discardableResult
    public func add(
        popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        strategy: TFYPopupPriorityStrategy,
        completion: (() -> Void)?
    ) -> Bool {
        let canBeReplaced = popup.configuration.canBeReplacedByHigherPriority
        var queuedItem: TFYSwiftPopupPriorityItem?
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()
            guard !containsPopupLocked(popup), hasTotalCapacityLocked() else {
                mutation.currentHighestPriority = mutation.previousHighestPriority
                return mutation
            }
            let item = makeWaitingItemLocked(
                popup: popup,
                priority: priority,
                strategy: strategy,
                maxWaitingTime: _defaultMaxWaitingTime,
                canBeReplaced: canBeReplaced,
                onDiscard: nil,
                showBlock: completion ?? {}
            )
            insertWaitingItemLocked(item)
            queuedItem = item
            mutation.didChange = true
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }
        guard mutation.didChange else { return false }
        updatePopupConfiguration(popup, priority: priority, canBeReplaced: canBeReplaced)
        notify(mutation)
        processNext()
        if let queuedItem { scheduleExpiry(for: queuedItem) }
        return true
    }

    /// 根据策略请求展示弹窗。
    ///
    /// 整个“检查容量 → 选择替换对象 → 占用展示槽/入队”过程是原子的。
    /// `onDiscard` 只会用于已成功入队、但随后因过期/取消/清理而未展示的请求。
    @discardableResult
    public func requestShow(
        popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        strategy: TFYPopupPriorityStrategy,
        maxWaitingTime: TimeInterval,
        canBeReplaced: Bool,
        onDiscard: (() -> Void)? = nil,
        showBlock: @escaping () -> Void
    ) -> Bool {
        let outcome = stateQueue.sync {
            requestShowLocked(
                popup: popup,
                priority: priority,
                strategy: strategy,
                maxWaitingTime: maxWaitingTime,
                canBeReplaced: canBeReplaced,
                onDiscard: onDiscard,
                showBlock: showBlock
            )
        }
        guard outcome.isAccepted else { return false }

        updatePopupConfiguration(popup, priority: priority, canBeReplaced: canBeReplaced)
        scheduleDismissals(outcome.popupsToDismiss, isReplacement: !outcome.popupsToDismiss.isEmpty)
        performOnMain(outcome.discardBlocks)
        if let popup = outcome.popupToShow, let block = outcome.showBlock {
            scheduleShow(popup: popup, block: block)
        }
        if let item = outcome.queuedItem { scheduleExpiry(for: item) }
        notifyQueueChanged(
            previousHighest: outcome.previousHighestPriority,
            currentHighest: outcome.currentHighestPriority
        )
        logPriorityQueue()
        return true
    }

    /// 设置队列总容量上限。缩小容量不会强制移除现有弹窗，只影响后续请求。
    public func enforceMaxPopupCount(_ count: Int) {
        stateQueue.sync { _maxPopupCount = max(0, count) }
    }

    public func remove(popup: TFYSwiftPopupView) {
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()
            if let index = internalWaitingQueue.firstIndex(where: { $0.popupView === popup }) {
                let item = internalWaitingQueue.remove(at: index)
                if let discard = item.consumeForDiscard() { mutation.discardBlocks.append(discard) }
                mutation.didChange = true
            }
            if let index = displayedPopups.firstIndex(where: { $0 === popup }) {
                displayedPopups.remove(at: index)
                let identifier = ObjectIdentifier(popup)
                if let discard = displayedMetadata.removeValue(forKey: identifier)?.pendingDiscardBlock {
                    mutation.discardBlocks.append(discard)
                }
                // `remove` 是弹窗完成关闭后的反向通知，不应重新进入待关闭状态。
                pendingDismissalIDs.remove(identifier)
                mutation.didChange = true
            }
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }
        notify(mutation)
        processNext()
    }

    /// 仅取消尚未展示的请求；成功取消时会执行对应 `onDiscard`。
    @discardableResult
    public func cancelWaitingPopup(_ popup: TFYSwiftPopupView) -> Bool {
        var didCancel = false
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()
            if let index = internalWaitingQueue.firstIndex(where: { $0.popupView === popup }) {
                let item = internalWaitingQueue.remove(at: index)
                if let discard = item.consumeForDiscard() { mutation.discardBlocks.append(discard) }
                mutation.didChange = true
                didCancel = true
            }
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }
        guard didCancel else { return false }
        notify(mutation)
        processNext()
        return didCancel
    }

    /// 尝试用等待队列补满可用展示槽。
    public func processNext() {
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()
            guard !_isQueuePaused else {
                mutation.currentHighestPriority = mutation.previousHighestPriority
                return mutation
            }

            if _autoCleanupExpiredPopups {
                let cleanup = removeExpiredWaitingItemsLocked()
                mutation.didChange = cleanup.didChange
                mutation.discardBlocks.append(contentsOf: cleanup.discardBlocks)
            }

            while displayedPopups.count < _maxSimultaneousPopups,
                  let index = internalWaitingQueue.firstIndex(where: { !$0.isExpired && $0.popupView != nil }) {
                let item = internalWaitingQueue.remove(at: index)
                guard let (popup, block, discard) = item.consumeForDisplay(), !containsPopupLocked(popup) else {
                    mutation.didChange = true
                    continue
                }
                trackDisplayedLocked(
                    popup,
                    priority: item.priority,
                    canBeReplaced: item.canBeReplacedByHigherPriority,
                    pendingDiscardBlock: discard
                )
                mutation.shows.append((popup, block))
                mutation.didChange = true
            }
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }

        mutation.shows.forEach { scheduleShow(popup: $0.popup, block: $0.block) }
        notify(mutation)
    }

    // MARK: - Inspection

    public func snapshot() -> TFYSwiftPopupPrioritySnapshot {
        stateQueue.sync {
            TFYSwiftPopupPrioritySnapshot(
                displayedPopups: displayedPopups,
                waitingItems: internalWaitingQueue,
                pendingDismissalCount: pendingDismissalIDs.count,
                isPaused: _isQueuePaused,
                highestPriority: highestPriorityLocked()
            )
        }
    }

    public func popupPriority(for popup: TFYSwiftPopupView) -> TFYPopupPriority {
        stateQueue.sync {
            displayedMetadata[ObjectIdentifier(popup)]?.priority
                ?? internalWaitingQueue.first(where: { $0.popupView === popup })?.priority
                ?? popup.configuration.priority
        }
    }

    public func currentHighestPriority() -> TFYPopupPriority {
        stateQueue.sync { highestPriorityLocked() }
    }

    public func popups(withPriority priority: TFYPopupPriority) -> [TFYSwiftPopupView] {
        stateQueue.sync {
            displayedPopups.filter {
                displayedMetadata[ObjectIdentifier($0)]?.priority == priority
            } + internalWaitingQueue
                .filter { $0.priority == priority }
                .compactMap(\.popupView)
        }
    }

    public func currentDisplayedPopups() -> [TFYSwiftPopupView] {
        stateQueue.sync { displayedPopups }
    }

    public func waitingQueue() -> [TFYSwiftPopupPriorityItem] {
        stateQueue.sync { internalWaitingQueue }
    }

    public func totalQueueCount() -> Int {
        stateQueue.sync { displayedPopups.count + internalWaitingQueue.count }
    }

    // MARK: - Clearing and control

    /// 清除低于指定优先级的等待项，并关闭对应的展示中弹窗。
    public func clearPopups(withPriorityLowerThan priority: TFYPopupPriority) {
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()

            for index in internalWaitingQueue.indices.reversed()
            where internalWaitingQueue[index].priority.rawValue < priority.rawValue {
                let item = internalWaitingQueue.remove(at: index)
                if let discard = item.consumeForDiscard() { mutation.discardBlocks.append(discard) }
                mutation.didChange = true
            }

            for index in displayedPopups.indices.reversed() {
                let popup = displayedPopups[index]
                let rawPriority = displayedMetadata[ObjectIdentifier(popup)]?.priority.rawValue ?? 0
                guard rawPriority < priority.rawValue else { continue }
                if let discard = removeDisplayedLocked(at: index, into: &mutation.popupsToDismiss) {
                    mutation.discardBlocks.append(discard)
                }
                mutation.didChange = true
            }
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }
        scheduleDismissals(mutation.popupsToDismiss, isReplacement: false)
        notify(mutation)
        processNext()
    }

    /// 清空等待队列，不影响已经展示的弹窗。
    public func clearWaitingQueue() {
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()
            let hadWaitingItems = !internalWaitingQueue.isEmpty
            mutation.discardBlocks = discardAllWaitingItemsLocked()
            mutation.didChange = hadWaitingItems
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }
        notify(mutation)
    }

    public func clearExpiredWaitingPopups() {
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()
            let cleanup = removeExpiredWaitingItemsLocked()
            mutation.didChange = cleanup.didChange
            mutation.discardBlocks = cleanup.discardBlocks
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }
        notify(mutation)
        processNext()
    }

    public func pauseQueue() {
        let changed = stateQueue.sync { () -> Bool in
            guard !_isQueuePaused else { return false }
            _isQueuePaused = true
            return true
        }
        if changed { postOnMain(name: .tfyPopupQueueDidUpdate) }
    }

    public func resumeQueue() {
        let changed = stateQueue.sync { () -> Bool in
            guard _isQueuePaused else { return false }
            _isQueuePaused = false
            return true
        }
        if changed { postOnMain(name: .tfyPopupQueueDidUpdate) }
        processNext()
    }

    /// 清空等待队列，并强制关闭所有由管理器跟踪的展示中弹窗。
    public func clearAllQueues() {
        let mutation = stateQueue.sync { () -> QueueMutation in
            var mutation = QueueMutation()
            mutation.previousHighestPriority = highestPriorityLocked()
            let hadWaitingItems = !internalWaitingQueue.isEmpty
            mutation.discardBlocks = discardAllWaitingItemsLocked()
            mutation.didChange = hadWaitingItems || !displayedPopups.isEmpty
            while !displayedPopups.isEmpty {
                if let discard = removeDisplayedLocked(
                    at: displayedPopups.index(before: displayedPopups.endIndex),
                    into: &mutation.popupsToDismiss
                ) {
                    mutation.discardBlocks.append(discard)
                }
            }
            mutation.currentHighestPriority = highestPriorityLocked()
            return mutation
        }
        scheduleDismissals(mutation.popupsToDismiss, isReplacement: false)
        notify(mutation)
    }

    // MARK: - Debugging

    public static func enablePriorityDebugMode(_ enabled: Bool) {
        shared.stateQueue.sync { shared._debugEnabled = enabled }
    }

    public static func isPriorityDebugModeEnabled() -> Bool {
        shared.stateQueue.sync { shared._debugEnabled }
    }

    public func logPriorityQueue() {
        let state = snapshot()
        guard Self.isPriorityDebugModeEnabled() else { return }
        print(
            "[TFYPopupPriority] displayed=\(state.displayedCount) "
                + "waiting=\(state.waitingCount) dismissing=\(state.pendingDismissalCount) "
                + "highest=\(Self.priorityDescription(state.highestPriority)) paused=\(state.isPaused)"
        )
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

    // MARK: - Atomic state transitions

    private func requestShowLocked(
        popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        strategy: TFYPopupPriorityStrategy,
        maxWaitingTime: TimeInterval,
        canBeReplaced: Bool,
        onDiscard: (() -> Void)?,
        showBlock: @escaping () -> Void
    ) -> RequestOutcome {
        var outcome = RequestOutcome()
        outcome.previousHighestPriority = highestPriorityLocked()
        guard !containsPopupLocked(popup) else {
            outcome.currentHighestPriority = outcome.previousHighestPriority
            return outcome
        }

        switch strategy {
        case .overlay:
            guard hasTotalCapacityLocked() else { break }
            trackDisplayedLocked(
                popup,
                priority: priority,
                canBeReplaced: canBeReplaced,
                pendingDiscardBlock: onDiscard
            )
            outcome.isAccepted = true
            outcome.popupToShow = popup
            outcome.showBlock = showBlock

        case .replace:
            while !displayedPopups.isEmpty {
                if let discard = removeDisplayedLocked(
                    at: displayedPopups.index(before: displayedPopups.endIndex),
                    into: &outcome.popupsToDismiss
                ) {
                    outcome.discardBlocks.append(discard)
                }
            }
            while !hasTotalCapacityLocked(), !internalWaitingQueue.isEmpty {
                let item = internalWaitingQueue.removeLast()
                if let discard = item.consumeForDiscard() { outcome.discardBlocks.append(discard) }
            }
            guard hasTotalCapacityLocked() else { break }
            trackDisplayedLocked(
                popup,
                priority: priority,
                canBeReplaced: canBeReplaced,
                pendingDiscardBlock: onDiscard
            )
            outcome.isAccepted = true
            outcome.popupToShow = popup
            outcome.showBlock = showBlock

        case .queue, .reject:
            let shouldDeferQueueRequest = _isQueuePaused && strategy == .queue
            if !shouldDeferQueueRequest,
               displayedPopups.count < _maxSimultaneousPopups,
               hasTotalCapacityLocked() {
                trackDisplayedLocked(
                    popup,
                    priority: priority,
                    canBeReplaced: canBeReplaced,
                    pendingDiscardBlock: onDiscard
                )
                outcome.isAccepted = true
                outcome.popupToShow = popup
                outcome.showBlock = showBlock
                break
            }

            if !shouldDeferQueueRequest,
               let replacementIndex = replacementCandidateIndexLocked(for: priority) {
                if let discard = removeDisplayedLocked(at: replacementIndex, into: &outcome.popupsToDismiss) {
                    outcome.discardBlocks.append(discard)
                }
                trackDisplayedLocked(
                    popup,
                    priority: priority,
                    canBeReplaced: canBeReplaced,
                    pendingDiscardBlock: onDiscard
                )
                outcome.isAccepted = true
                outcome.popupToShow = popup
                outcome.showBlock = showBlock
                break
            }

            guard strategy == .queue, hasTotalCapacityLocked() else { break }
            let item = makeWaitingItemLocked(
                popup: popup,
                priority: priority,
                strategy: strategy,
                maxWaitingTime: maxWaitingTime,
                canBeReplaced: canBeReplaced,
                onDiscard: onDiscard,
                showBlock: showBlock
            )
            insertWaitingItemLocked(item)
            outcome.isAccepted = true
            outcome.queuedItem = item
        }

        outcome.currentHighestPriority = highestPriorityLocked()
        return outcome
    }

    private func makeWaitingItemLocked(
        popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        strategy: TFYPopupPriorityStrategy,
        maxWaitingTime: TimeInterval,
        canBeReplaced: Bool,
        onDiscard: (() -> Void)?,
        showBlock: @escaping () -> Void
    ) -> TFYSwiftPopupPriorityItem {
        let waitingTime = maxWaitingTime > 0 && maxWaitingTime.isFinite
            ? maxWaitingTime
            : _defaultMaxWaitingTime
        return TFYSwiftPopupPriorityItem(
            popupView: popup,
            priority: priority,
            strategy: strategy,
            maxWaitingTime: waitingTime,
            completion: showBlock,
            discard: onDiscard,
            canBeReplaced: canBeReplaced
        )
    }

    private func trackDisplayedLocked(
        _ popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        canBeReplaced: Bool,
        pendingDiscardBlock: (() -> Void)?
    ) {
        displayedPopups.append(popup)
        displayedMetadata[ObjectIdentifier(popup)] = DisplayedMetadata(
            priority: priority,
            canBeReplaced: canBeReplaced,
            pendingDiscardBlock: pendingDiscardBlock
        )
    }

    @discardableResult
    private func removeDisplayedLocked(
        at index: Int,
        into removed: inout [TFYSwiftPopupView]
    ) -> (() -> Void)? {
        let popup = displayedPopups.remove(at: index)
        let identifier = ObjectIdentifier(popup)
        let pendingDiscardBlock = displayedMetadata.removeValue(forKey: identifier)?.pendingDiscardBlock
        pendingDismissalIDs.insert(identifier)
        removed.append(popup)
        return pendingDiscardBlock
    }

    /// 只选择一个最低优先级、最早展示的候选者，释放一个槽位即可。
    private func replacementCandidateIndexLocked(for incomingPriority: TFYPopupPriority) -> Int? {
        displayedPopups.indices
            .filter { index in
                guard let metadata = displayedMetadata[ObjectIdentifier(displayedPopups[index])] else { return false }
                return metadata.canBeReplaced
                    && TFYPopupPriority.isHigher(incomingPriority, than: metadata.priority)
            }
            .min { lhs, rhs in
                let lhsPriority = displayedMetadata[ObjectIdentifier(displayedPopups[lhs])]?.priority.rawValue ?? 0
                let rhsPriority = displayedMetadata[ObjectIdentifier(displayedPopups[rhs])]?.priority.rawValue ?? 0
                if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
                return lhs < rhs
            }
    }

    private func containsPopupLocked(_ popup: TFYSwiftPopupView) -> Bool {
        let identifier = ObjectIdentifier(popup)
        return pendingDismissalIDs.contains(identifier)
            || displayedMetadata[identifier] != nil
            || internalWaitingQueue.contains { $0.popupView === popup }
    }

    private func hasTotalCapacityLocked() -> Bool {
        _maxPopupCount == 0
            || displayedPopups.count + internalWaitingQueue.count < _maxPopupCount
    }

    private func insertWaitingItemLocked(_ item: TFYSwiftPopupPriorityItem) {
        let index = internalWaitingQueue.firstIndex {
            TFYPopupPriority.isHigher(item.priority, than: $0.priority)
        } ?? internalWaitingQueue.endIndex
        internalWaitingQueue.insert(item, at: index)
    }

    private func highestPriorityLocked() -> TFYPopupPriority {
        let displayedPriorities = displayedMetadata.values.map(\.priority.rawValue)
        let waitingPriorities = internalWaitingQueue
            .filter { !$0.isExpired && $0.popupView != nil }
            .map(\.priority.rawValue)
        return TFYPopupPriority.fromValue((displayedPriorities + waitingPriorities).max() ?? 0)
    }

    private func removeExpiredWaitingItemsLocked() -> (didChange: Bool, discardBlocks: [() -> Void]) {
        var discardBlocks: [() -> Void] = []
        var didChange = false
        for index in internalWaitingQueue.indices.reversed()
        where internalWaitingQueue[index].isExpired || internalWaitingQueue[index].popupView == nil {
            let item = internalWaitingQueue.remove(at: index)
            if let discard = item.consumeForDiscard() { discardBlocks.append(discard) }
            didChange = true
        }
        return (didChange, discardBlocks)
    }

    private func discardAllWaitingItemsLocked() -> [() -> Void] {
        let items = internalWaitingQueue
        internalWaitingQueue.removeAll()
        return items.compactMap { $0.consumeForDiscard() }
    }

    // MARK: - Main-thread effects

    private func scheduleShow(popup: TFYSwiftPopupView, block: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self, weak popup] in
            guard let self, let popup, self.beginScheduledShow(popup) else { return }
            block()
        }
    }

    /// 原子地把“已占槽、待执行 showBlock”推进到“已开始展示”，确保取消与展示只会命中一个分支。
    private func beginScheduledShow(_ popup: TFYSwiftPopupView) -> Bool {
        stateQueue.sync {
            let identifier = ObjectIdentifier(popup)
            guard var metadata = displayedMetadata[identifier] else { return false }
            metadata.pendingDiscardBlock = nil
            displayedMetadata[identifier] = metadata
            return true
        }
    }

    private func scheduleDismissals(_ popups: [TFYSwiftPopupView], isReplacement: Bool) {
        guard !popups.isEmpty else { return }
        let dismiss = { [weak self] in
            guard let self else { return }
            for popup in popups {
                let identifier = ObjectIdentifier(popup)
                popup.dismissAnimated(false, force: true) { [weak self] in
                    self?.finishPendingDismissal(identifier)
                }
            }
            if isReplacement {
                NotificationCenter.default.post(name: .tfyPopupDidReplace, object: self)
            }
        }
        if Thread.isMainThread {
            dismiss()
        } else {
            DispatchQueue.main.async(execute: dismiss)
        }
    }

    private func finishPendingDismissal(_ identifier: ObjectIdentifier) {
        _ = stateQueue.sync { pendingDismissalIDs.remove(identifier) }
        processNext()
    }

    private func scheduleExpiry(for item: TFYSwiftPopupPriorityItem) {
        guard item.maxWaitingTime > 0 else { return }
        let workItem = DispatchWorkItem { [weak self, weak item] in
            guard let self, let item, item.isExpired, self.autoCleanupExpiredPopups else { return }
            self.clearExpiredWaitingPopups()
        }
        let shouldSchedule = stateQueue.sync { () -> Bool in
            guard internalWaitingQueue.contains(where: { $0 === item }) else { return false }
            item.expiryWorkItem?.cancel()
            item.expiryWorkItem = workItem
            return true
        }
        if shouldSchedule {
            DispatchQueue.main.asyncAfter(deadline: .now() + item.maxWaitingTime, execute: workItem)
        }
    }

    private func updatePopupConfiguration(
        _ popup: TFYSwiftPopupView,
        priority: TFYPopupPriority,
        canBeReplaced: Bool
    ) {
        let update = {
            popup.configuration.priority = priority
            popup.configuration.canBeReplacedByHigherPriority = canBeReplaced
        }
        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.sync(execute: update)
        }
    }

    private func notify(_ mutation: QueueMutation) {
        guard mutation.didChange else { return }
        performOnMain(mutation.discardBlocks)
        notifyQueueChanged(
            previousHighest: mutation.previousHighestPriority,
            currentHighest: mutation.currentHighestPriority
        )
    }

    private func notifyQueueChanged(
        previousHighest: TFYPopupPriority,
        currentHighest: TFYPopupPriority
    ) {
        postOnMain(name: .tfyPopupQueueDidUpdate)
        guard previousHighest != currentHighest else { return }
        postOnMain(
            name: .tfyPopupPriorityDidChange,
            userInfo: [
                TFYPopupPriorityNotificationKey.previousPriority: previousHighest,
                TFYPopupPriorityNotificationKey.currentPriority: currentHighest,
            ]
        )
    }

    private func postOnMain(name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        let post = { NotificationCenter.default.post(name: name, object: self, userInfo: userInfo) }
        if Thread.isMainThread {
            post()
        } else {
            DispatchQueue.main.async(execute: post)
        }
    }

    private func performOnMain(_ blocks: [() -> Void]) {
        guard !blocks.isEmpty else { return }
        let perform = { blocks.forEach { $0() } }
        if Thread.isMainThread {
            perform()
        } else {
            DispatchQueue.main.async(execute: perform)
        }
    }
}
