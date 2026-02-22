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
    public var discoveryInterval: TimeInterval = 5.0
    public var enableContainerChangeNotifications = true
    public var enableDebugMode = false

    private var discoveredContainers: [TFYSwiftPopupContainerInfo] = []
    private var customContainers: [TFYSwiftPopupContainerInfo] = []
    private let managerQueue = DispatchQueue(label: "com.tfy.popup.container.manager", attributes: .concurrent)
    private var discoveryTimer: Timer?
    private let selectorLock = NSLock()
    private var _defaultSelector: TFYSwiftPopupContainerSelector

    public override init() {
        let sel = TFYSwiftDefaultPopupContainerSelector(strategy: .auto)
        sel.preferCurrentViewController = false
        sel.preferWindowContainer = true
        _defaultSelector = sel
        super.init()
        startAutoDiscovery()
        setupApplicationStateObservers()
    }

    deinit {
        stopAutoDiscovery()
    }

    // MARK: - Container Discovery

    public func discoverAvailableContainers(completion: @escaping TFYPopupContainerDiscoveryCallback) {
        managerQueue.async { [weak self] in
            guard let self = self else { return }
            var containers: [TFYSwiftPopupContainerInfo] = []
            containers.append(contentsOf: self.discoverWindowContainers())
            containers.append(contentsOf: self.discoverViewControllerContainers())
            containers.append(contentsOf: self.discoverViewContainers())
            containers.append(contentsOf: self.customContainers)

            if containers.isEmpty {
                let error = NSError(domain: "TFYPopupContainerManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "没有发现可用的容器"])
                DispatchQueue.main.async { completion([], error) }
                return
            }

            self.managerQueue.async(flags: .barrier) {
                self.discoveredContainers = containers
            }

            if self.enableContainerChangeNotifications {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .tfyPopupContainerDidChange, object: self, userInfo: ["containers": containers])
                }
            }
            DispatchQueue.main.async { completion(containers, nil) }
        }
    }

    public func discoverContainers(ofType type: TFYPopupContainerType, completion: @escaping TFYPopupContainerDiscoveryCallback) {
        managerQueue.async { [weak self] in
            guard let self = self else { return }
            let containers: [TFYSwiftPopupContainerInfo]
            switch type {
            case .window: containers = self.discoverWindowContainers()
            case .viewController: containers = self.discoverViewControllerContainers()
            case .view: containers = self.discoverViewContainers()
            case .custom: containers = Array(self.customContainers)
            }
            DispatchQueue.main.async { completion(containers, nil) }
        }
    }

    public func currentAvailableContainers() -> [TFYSwiftPopupContainerInfo] {
        managerQueue.sync { discoveredContainers }
    }

    public func currentAvailableContainers(ofType type: TFYPopupContainerType) -> [TFYSwiftPopupContainerInfo] {
        currentAvailableContainers().filter { $0.type == type }
    }

    // MARK: - Container Management

    public func registerCustomContainer(_ containerInfo: TFYSwiftPopupContainerInfo) {
        guard let view = containerInfo.containerView else { return }
        managerQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            let exists = self.customContainers.contains { $0.containerView === view }
            if !exists {
                self.customContainers.append(containerInfo)
                if self.enableContainerChangeNotifications {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .tfyPopupContainerDidBecomeAvailable, object: self, userInfo: ["container": containerInfo])
                    }
                }
            }
        }
    }

    public func unregisterCustomContainer(_ containerInfo: TFYSwiftPopupContainerInfo) {
        managerQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.customContainers.removeAll { $0 === containerInfo }
            if self.enableContainerChangeNotifications {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .tfyPopupContainerDidBecomeUnavailable, object: self, userInfo: ["container": containerInfo])
                }
            }
        }
    }

    public func isContainerAvailable(_ containerInfo: TFYSwiftPopupContainerInfo) -> Bool {
        guard let cv = containerInfo.containerView, cv.window != nil else { return false }
        let list = managerQueue.sync { discoveredContainers }
        return list.contains { $0.containerView === cv }
    }

    public func refreshContainerStates() {
        discoverAvailableContainers { [weak self] containers, _ in
            if self?.enableDebugMode == true {
                print("TFYPopupContainerManager: 刷新容器状态完成，发现 \(containers.count) 个容器")
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

    private func getCurrentKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene, windowScene.activationState == .foregroundActive else { continue }
                for window in windowScene.windows where window.isKeyWindow {
                    return window
                }
            }
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows where !window.isHidden && window.windowLevel.rawValue >= UIWindow.Level.normal.rawValue {
                    return window
                }
            }
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene, let first = windowScene.windows.first else { continue }
                return first
            }
        }
        return nil
    }

    private func discoverWindowContainers() -> [TFYSwiftPopupContainerInfo] {
        if !Thread.isMainThread {
            var result: [TFYSwiftPopupContainerInfo] = []
            DispatchQueue.main.sync { result = self.discoverWindowContainers() }
            return result
        }
        var containers: [TFYSwiftPopupContainerInfo] = []
        if #available(iOS 15.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene, windowScene.activationState == .foregroundActive else { continue }
                for window in windowScene.windows where !window.isHidden && window.windowLevel.rawValue >= UIWindow.Level.normal.rawValue {
                    containers.append(TFYSwiftPopupContainerInfo.windowContainer(window))
                }
            }
            if containers.isEmpty {
                for scene in UIApplication.shared.connectedScenes {
                    guard let windowScene = scene as? UIWindowScene else { continue }
                    for window in windowScene.windows where !window.isHidden && window.windowLevel.rawValue >= UIWindow.Level.normal.rawValue {
                        containers.append(TFYSwiftPopupContainerInfo.windowContainer(window))
                    }
                }
            }
            if containers.isEmpty {
                for scene in UIApplication.shared.connectedScenes {
                    guard let windowScene = scene as? UIWindowScene, let first = windowScene.windows.first else { continue }
                    containers.append(TFYSwiftPopupContainerInfo.windowContainer(first))
                    break
                }
            }
        }
        return containers
    }

    private func discoverViewControllerContainers() -> [TFYSwiftPopupContainerInfo] {
        if !Thread.isMainThread {
            var result: [TFYSwiftPopupContainerInfo] = []
            DispatchQueue.main.sync { result = self.discoverViewControllerContainers() }
            return result
        }
        var containers: [TFYSwiftPopupContainerInfo] = []
        if let keyWindow = getCurrentKeyWindow(), let root = keyWindow.rootViewController {
            addViewControllerContainers(root, to: &containers)
        }
        return containers
    }

    private func addViewControllerContainers(_ viewController: UIViewController?, to containers: inout [TFYSwiftPopupContainerInfo]) {
        guard let vc = viewController else { return }
        if !Thread.isMainThread {
            DispatchQueue.main.sync { self.addViewControllerContainers(vc, to: &containers) }
            return
        }
        guard vc.isViewLoaded, vc.view != nil else { return }
        if let info = TFYSwiftPopupContainerInfo.viewControllerContainer(vc) {
            containers.append(info)
        }
        for child in vc.children { addViewControllerContainers(child, to: &containers) }
        if let presented = vc.presentedViewController { addViewControllerContainers(presented, to: &containers) }
    }

    private func discoverViewContainers() -> [TFYSwiftPopupContainerInfo] {
        if !Thread.isMainThread {
            var result: [TFYSwiftPopupContainerInfo] = []
            DispatchQueue.main.sync { result = self.discoverViewContainers() }
            return result
        }
        var containers: [TFYSwiftPopupContainerInfo] = []
        if let keyWindow = getCurrentKeyWindow() {
            addViewContainers(keyWindow, to: &containers)
        }
        return containers
    }

    private func addViewContainers(_ view: UIView?, to containers: inout [TFYSwiftPopupContainerInfo]) {
        guard let v = view else { return }
        if !Thread.isMainThread {
            DispatchQueue.main.sync { self.addViewContainers(v, to: &containers) }
            return
        }
        if v.bounds.width > 100 && v.bounds.height > 100 && !v.isHidden {
            let name = "View_\(Unmanaged.passUnretained(v).toOpaque())_\(type(of: v))"
            containers.append(TFYSwiftPopupContainerInfo.viewContainer(v, name: name))
        }
        for subview in v.subviews { addViewContainers(subview, to: &containers) }
    }

    private func startAutoDiscovery() {
        guard enableAutoDiscovery, discoveryTimer == nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let timer = Timer(timeInterval: self.discoveryInterval, repeats: true) { [weak self] _ in
                self?.refreshContainerStates()
            }
            self.discoveryTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopAutoDiscovery() {
        DispatchQueue.main.async { [weak self] in
            self?.discoveryTimer?.invalidate()
            self?.discoveryTimer = nil
        }
    }

    private func setupApplicationStateObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }

    @objc private func applicationDidBecomeActive() {
        startAutoDiscovery()
        refreshContainerStates()
    }

    @objc private func applicationWillResignActive() {
        stopAutoDiscovery()
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
        print("=== TFYPopupContainerManager 当前容器状态 ===")
        print("总容器数量: \(containers.count)")
        for c in containers {
            print("- \(c.name) (\(Self.description(forContainerType: c.type))): \(c.containerDescription) - 可用: \(c.isAvailable ? "是" : "否")")
        }
        print("==========================================")
    }
}

// MARK: - Convenience

public enum TFYSwiftPopupContainerManagerConvenience {
    public static func getCurrentWindowContainer() -> TFYSwiftPopupContainerInfo? {
        func find() -> UIWindow? {
            if #available(iOS 15.0, *) {
                for scene in UIApplication.shared.connectedScenes {
                    guard let ws = scene as? UIWindowScene, ws.activationState == .foregroundActive else { continue }
                    for w in ws.windows where w.isKeyWindow { return w }
                }
            }
            for scene in UIApplication.shared.connectedScenes {
                guard let ws = scene as? UIWindowScene, let first = ws.windows.first else { continue }
                return first
            }
            return nil
        }
        if Thread.isMainThread {
            guard let w = find() else { return nil }
            return TFYSwiftPopupContainerInfo.windowContainer(w)
        }
        var result: TFYSwiftPopupContainerInfo?
        DispatchQueue.main.sync {
            guard let w = find() else { return }
            result = TFYSwiftPopupContainerInfo.windowContainer(w)
        }
        return result
    }

    public static func getCurrentViewControllerContainer() -> TFYSwiftPopupContainerInfo? {
        func onMain() -> TFYSwiftPopupContainerInfo? {
            guard let windowInfo = getCurrentWindowContainer(), let window = windowInfo.containerView as? UIWindow else { return nil }
            guard let root = window.rootViewController else { return nil }
            return TFYSwiftPopupContainerInfo.viewControllerContainer(root)
        }
        if Thread.isMainThread { return onMain() }
        var result: TFYSwiftPopupContainerInfo?
        DispatchQueue.main.sync { result = onMain() }
        return result
    }

    public static func getContainer(forView view: UIView) -> TFYSwiftPopupContainerInfo {
        let name = "View_\(Unmanaged.passUnretained(view).toOpaque())_\(type(of: view))"
        return TFYSwiftPopupContainerInfo.viewContainer(view, name: name)
    }

    public static func getContainer(forViewController viewController: UIViewController) -> TFYSwiftPopupContainerInfo? {
        TFYSwiftPopupContainerInfo.viewControllerContainer(viewController)
    }
}
