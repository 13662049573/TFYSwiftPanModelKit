//
//  TFYSwiftPopupContainerManager.swift
//  TFYSwiftPanModel
//
//  弹窗容器管理器，由 OC TFYPopupContainerManager 迁移。
//

import UIKit

/// 容器发现回调
public typealias TFYPopupContainerDiscoveryCallback = ([TFYSwiftPopupContainerInfo], Error?) -> Void

// MARK: - 通知名

public extension Notification.Name {
    static let tfyPopupContainerDidChange = Notification.Name("TFYPopupContainerDidChangeNotification")
    static let tfyPopupContainerDidBecomeAvailable = Notification.Name("TFYPopupContainerDidBecomeAvailableNotification")
    static let tfyPopupContainerDidBecomeUnavailable = Notification.Name("TFYPopupContainerDidBecomeUnavailableNotification")
}

// MARK: - 容器管理器

public final class TFYSwiftPopupContainerManager: NSObject {
    public static let shared = TFYSwiftPopupContainerManager()

    public var enableAutoDiscovery = true
    /// 自动发现间隔；默认更长以降低 CPU，展示时会主动刷新
    public var discoveryInterval: TimeInterval = 30.0
    public var enableContainerChangeNotifications = true
    public var enableDebugMode = false

    private var discoveredContainers: [TFYSwiftPopupContainerInfo] = []
    private var customContainers: [TFYSwiftPopupContainerInfo] = []
    private let stateLock = NSLock()
    private var discoveryTimer: Timer?
    private let selectorLock = NSLock()
    private var _defaultSelector: TFYSwiftPopupContainerSelector
    private var applicationObservers: [NSObjectProtocol] = []
    private var sceneObservers: [NSObjectProtocol] = []

    public override init() {
        let sel = TFYSwiftDefaultPopupContainerSelector(strategy: .auto)
        sel.preferCurrentViewController = false
        sel.preferWindowContainer = true
        _defaultSelector = sel
        super.init()
        setupApplicationStateObservers()
        // 启动时发现一次；之后依赖 scene 变化与展示时刷新，避免每 5s 全树遍历
        refreshContainerStates()
        startAutoDiscovery()
    }

    deinit {
        stopAutoDiscovery()
        removeAllObservers()
    }

    // MARK: - Container Discovery

    public func discoverAvailableContainers(completion: @escaping TFYPopupContainerDiscoveryCallback) {
        let work = { [weak self] in
            guard let self else { return }
            var containers: [TFYSwiftPopupContainerInfo] = []
            containers.append(contentsOf: self.discoverWindowContainers())
            containers.append(contentsOf: self.discoverViewControllerContainers())
            containers.append(contentsOf: self.discoverViewContainers())
            self.stateLock.lock()
            containers.append(contentsOf: self.customContainers)
            self.discoveredContainers = containers
            self.stateLock.unlock()

            if containers.isEmpty {
                let error = NSError(domain: "TFYPopupContainerManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No available containers found"])
                completion([], error)
                return
            }

            if self.enableContainerChangeNotifications {
                NotificationCenter.default.post(name: .tfyPopupContainerDidChange, object: self, userInfo: ["containers": containers])
            }
            completion(containers, nil)
        }

        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    public func discoverContainers(ofType type: TFYPopupContainerType, completion: @escaping TFYPopupContainerDiscoveryCallback) {
        let work = { [weak self] in
            guard let self else { return }
            let containers: [TFYSwiftPopupContainerInfo]
            switch type {
            case .window: containers = self.discoverWindowContainers()
            case .viewController: containers = self.discoverViewControllerContainers()
            case .view: containers = self.discoverViewContainers()
            case .custom:
                self.stateLock.lock()
                containers = Array(self.customContainers)
                self.stateLock.unlock()
            }
            completion(containers, nil)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    public func currentAvailableContainers() -> [TFYSwiftPopupContainerInfo] {
        stateLock.lock()
        defer { stateLock.unlock() }
        return discoveredContainers
    }

    public func currentAvailableContainers(ofType type: TFYPopupContainerType) -> [TFYSwiftPopupContainerInfo] {
        currentAvailableContainers().filter { $0.type == type }
    }

    // MARK: - Container Management

    public func registerCustomContainer(_ containerInfo: TFYSwiftPopupContainerInfo) {
        guard let view = containerInfo.containerView else { return }
        stateLock.lock()
        let exists = customContainers.contains { $0.containerView === view }
        if !exists {
            customContainers.append(containerInfo)
        }
        stateLock.unlock()
        if !exists, enableContainerChangeNotifications {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .tfyPopupContainerDidBecomeAvailable, object: self, userInfo: ["container": containerInfo])
            }
        }
    }

    public func unregisterCustomContainer(_ containerInfo: TFYSwiftPopupContainerInfo) {
        stateLock.lock()
        customContainers.removeAll { $0 === containerInfo }
        stateLock.unlock()
        if enableContainerChangeNotifications {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .tfyPopupContainerDidBecomeUnavailable, object: self, userInfo: ["container": containerInfo])
            }
        }
    }

    public func isContainerAvailable(_ containerInfo: TFYSwiftPopupContainerInfo) -> Bool {
        guard let cv = containerInfo.containerView, cv.window != nil else { return false }
        stateLock.lock()
        defer { stateLock.unlock() }
        return discoveredContainers.contains { $0.containerView === cv }
    }

    public func refreshContainerStates() {
        discoverAvailableContainers { [weak self] containers, _ in
            if self?.enableDebugMode == true {
                print("TFYPopupContainerManager: refreshed, found \(containers.count) containers")
            }
        }
    }

    // MARK: - Container Selection

    public func setDefaultContainerSelector(_ selector: TFYSwiftPopupContainerSelector) {
        selectorLock.lock()
        _defaultSelector = selector
        selectorLock.unlock()
    }

    public func defaultContainerSelector() -> TFYSwiftPopupContainerSelector {
        selectorLock.lock()
        defer { selectorLock.unlock() }
        return _defaultSelector
    }

    public func selectBestContainer(completion: @escaping TFYPopupContainerSelectionCallback) {
        selectBestContainer(selector: defaultContainerSelector(), completion: completion)
    }

    public func selectBestContainer(selector: TFYSwiftPopupContainerSelector?, completion: @escaping TFYPopupContainerSelectionCallback) {
        discoverAvailableContainers { [weak self] containers, error in
            if let error = error {
                completion(nil, error)
                return
            }
            let sel = selector ?? self?.defaultContainerSelector()
            sel?.selectContainer(from: containers, completion: completion)
        }
    }

    // MARK: - Private: Window Discovery

    private func discoverWindowContainers() -> [TFYSwiftPopupContainerInfo] {
        var containers: [TFYSwiftPopupContainerInfo] = []
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene, windowScene.activationState == .foregroundActive else { continue }
            for window in windowScene.windows where !window.isHidden && window.windowLevel.rawValue >= UIWindow.Level.normal.rawValue {
                containers.append(TFYSwiftPopupContainerInfo.windowContainer(window))
            }
        }
        if containers.isEmpty, let window = TFYSwiftWindowHelper.activeWindow {
            containers.append(TFYSwiftPopupContainerInfo.windowContainer(window))
        }
        return containers
    }

    private func discoverViewControllerContainers() -> [TFYSwiftPopupContainerInfo] {
        var containers: [TFYSwiftPopupContainerInfo] = []
        if let keyWindow = TFYSwiftWindowHelper.activeWindow, let root = keyWindow.rootViewController {
            addViewControllerContainers(root, to: &containers)
        }
        return containers
    }

    private func addViewControllerContainers(_ viewController: UIViewController?, to containers: inout [TFYSwiftPopupContainerInfo]) {
        guard let vc = viewController, vc.isViewLoaded, vc.view != nil else { return }
        if let info = TFYSwiftPopupContainerInfo.viewControllerContainer(vc) {
            containers.append(info)
        }
        for child in vc.children { addViewControllerContainers(child, to: &containers) }
        if let presented = vc.presentedViewController { addViewControllerContainers(presented, to: &containers) }
    }

    private func discoverViewContainers() -> [TFYSwiftPopupContainerInfo] {
        var containers: [TFYSwiftPopupContainerInfo] = []
        if let keyWindow = TFYSwiftWindowHelper.activeWindow {
            // 仅扫描 window 的直接子视图一层 + 根 VC view，避免全树递归
            for subview in keyWindow.subviews where subview.bounds.width > 100 && subview.bounds.height > 100 && !subview.isHidden {
                let name = "View_\(Unmanaged.passUnretained(subview).toOpaque())_\(type(of: subview))"
                containers.append(TFYSwiftPopupContainerInfo.viewContainer(subview, name: name))
            }
        }
        return containers
    }

    private func startAutoDiscovery() {
        guard enableAutoDiscovery, discoveryTimer == nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let timer = Timer(timeInterval: self.discoveryInterval, repeats: true) { [weak self] _ in
                self?.refreshContainerStates()
            }
            self.discoveryTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopAutoDiscovery() {
        discoveryTimer?.invalidate()
        discoveryTimer = nil
    }

    private func setupApplicationStateObservers() {
        let center = NotificationCenter.default
        applicationObservers.append(center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.startAutoDiscovery()
            self?.refreshContainerStates()
        })
        applicationObservers.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.stopAutoDiscovery()
        })
        sceneObservers.append(center.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refreshContainerStates()
        })
        sceneObservers.append(center.addObserver(forName: UIScene.didDisconnectNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refreshContainerStates()
        })
    }

    private func removeAllObservers() {
        let center = NotificationCenter.default
        applicationObservers.forEach { center.removeObserver($0) }
        sceneObservers.forEach { center.removeObserver($0) }
        applicationObservers.removeAll()
        sceneObservers.removeAll()
    }

    // MARK: - Utility

    public static func description(forContainerType type: TFYPopupContainerType) -> String {
        switch type {
        case .window: return "UIWindow"
        case .view: return "UIView"
        case .viewController: return "UIViewController"
        case .custom: return "Custom"
        }
    }

    public static func description(forSelectionStrategy strategy: TFYPopupContainerSelectionStrategy) -> String {
        switch strategy {
        case .auto: return "Auto"
        case .manual: return "Manual"
        case .smart: return "Smart"
        case .custom: return "Custom"
        }
    }

    public func logCurrentContainerStates() {
        let containers = currentAvailableContainers()
        print("=== TFYPopupContainerManager ===")
        print("total: \(containers.count)")
        for c in containers {
            print("- \(c.name) (\(Self.description(forContainerType: c.type))): available=\(c.isAvailable)")
        }
    }
}

// MARK: - Convenience

public enum TFYSwiftPopupContainerManagerConvenience {
    public static func getCurrentWindowContainer() -> TFYSwiftPopupContainerInfo? {
        if Thread.isMainThread {
            guard let w = TFYSwiftWindowHelper.activeWindow else { return nil }
            return TFYSwiftPopupContainerInfo.windowContainer(w)
        }
        return TFYSwiftPopupContainerManager.shared.currentAvailableContainers(ofType: .window).first
    }

    public static func getCurrentViewControllerContainer() -> TFYSwiftPopupContainerInfo? {
        if Thread.isMainThread {
            guard let window = TFYSwiftWindowHelper.activeWindow,
                  let root = window.rootViewController else { return nil }
            return TFYSwiftPopupContainerInfo.viewControllerContainer(root)
        }
        return TFYSwiftPopupContainerManager.shared.currentAvailableContainers(ofType: .viewController).first
    }

    public static func getContainer(forView view: UIView) -> TFYSwiftPopupContainerInfo {
        let name = "View_\(Unmanaged.passUnretained(view).toOpaque())_\(type(of: view))"
        return TFYSwiftPopupContainerInfo.viewContainer(view, name: name)
    }

    public static func getContainer(forViewController viewController: UIViewController) -> TFYSwiftPopupContainerInfo? {
        TFYSwiftPopupContainerInfo.viewControllerContainer(viewController)
    }
}
