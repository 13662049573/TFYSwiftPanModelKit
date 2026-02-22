//
//  TFYSwiftPopupContainerType.swift
//  TFYSwiftPanModel
//
//  弹窗容器类型与选择器，由 OC TFYPopupContainerType 迁移。
//

import UIKit

/// 容器类型
public enum TFYPopupContainerType: UInt {
    case window = 0
    case view
    case viewController
    case custom
}

/// 容器选择策略
public enum TFYPopupContainerSelectionStrategy: UInt {
    case auto = 0
    case manual
    case smart
    case custom
}

/// 容器信息
public final class TFYSwiftPopupContainerInfo: NSObject {
    public let type: TFYPopupContainerType
    public weak var containerView: UIView?
    public let name: String
    public let containerDescription: String
    public let isAvailable: Bool
    public let priority: Int

    public init(
        type: TFYPopupContainerType,
        containerView: UIView,
        name: String,
        containerDescription: String,
        isAvailable: Bool,
        priority: Int
    ) {
        self.type = type
        self.containerView = containerView
        self.name = name
        self.containerDescription = containerDescription
        self.isAvailable = isAvailable
        self.priority = priority
        super.init()
    }

    public static func windowContainer(_ window: UIWindow) -> TFYSwiftPopupContainerInfo {
        let name = "Window_\(Unmanaged.passUnretained(window).toOpaque())"
        let desc = "UIWindow container (Level: \(window.windowLevel))"
        return TFYSwiftPopupContainerInfo(
            type: .window,
            containerView: window,
            name: name,
            containerDescription: desc,
            isAvailable: !window.isHidden,
            priority: 100
        )
    }

    public static func viewContainer(_ view: UIView, name: String) -> TFYSwiftPopupContainerInfo {
        let desc = "UIView container (\(Swift.type(of: view)))"
        return TFYSwiftPopupContainerInfo(
            type: .view,
            containerView: view,
            name: name,
            containerDescription: desc,
            isAvailable: view.window != nil,
            priority: 50
        )
    }

    public static func viewControllerContainer(_ viewController: UIViewController) -> TFYSwiftPopupContainerInfo? {
        guard let containerView = viewController.view else { return nil }
        let name = "ViewController_\(Unmanaged.passUnretained(viewController).toOpaque())"
        let desc = "UIViewController container (\(Swift.type(of: viewController)))"
        var isAvailable = true
        if Thread.isMainThread {
            isAvailable = containerView.window != nil
        }
        return TFYSwiftPopupContainerInfo(
            type: .viewController,
            containerView: containerView,
            name: name,
            containerDescription: desc,
            isAvailable: isAvailable,
            priority: 75
        )
    }
}

/// 容器选择回调
public typealias TFYPopupContainerSelectionCallback = (TFYSwiftPopupContainerInfo?, Error?) -> Void

/// 容器选择器协议
public protocol TFYSwiftPopupContainerSelector: AnyObject {
    func selectContainer(from availableContainers: [TFYSwiftPopupContainerInfo], completion: @escaping TFYPopupContainerSelectionCallback)
    func supportsContainerType(_ type: TFYPopupContainerType) -> Bool
    func priorityForContainer(_ containerInfo: TFYSwiftPopupContainerInfo) -> Int
}

public extension TFYSwiftPopupContainerSelector {
    func supportsContainerType(_ type: TFYPopupContainerType) -> Bool { true }
    func priorityForContainer(_ containerInfo: TFYSwiftPopupContainerInfo) -> Int { containerInfo.priority }
}

/// 默认容器选择器
public final class TFYSwiftDefaultPopupContainerSelector: NSObject, TFYSwiftPopupContainerSelector {
    public var strategy: TFYPopupContainerSelectionStrategy = .auto
    public var preferWindowContainer = true
    public var preferCurrentViewController = true
    public var customPriorityCalculator: ((TFYSwiftPopupContainerInfo) -> Int)?

    public override init() {
        super.init()
    }

    public init(strategy: TFYPopupContainerSelectionStrategy) {
        self.strategy = strategy
        super.init()
    }

    public func selectContainer(from availableContainers: [TFYSwiftPopupContainerInfo], completion: @escaping TFYPopupContainerSelectionCallback) {
        guard !availableContainers.isEmpty else {
            completion(nil, NSError(domain: "TFYPopupContainerError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "没有可用的容器"]))
            return
        }
        let valid = availableContainers.filter { $0.isAvailable }
        guard !valid.isEmpty else {
            completion(nil, NSError(domain: "TFYPopupContainerError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "没有可用的有效容器"]))
            return
        }
        let selected: TFYSwiftPopupContainerInfo?
        switch strategy {
        case .auto: selected = selectContainerAutomatically(valid)
        case .manual: selected = selectContainerManually(valid)
        case .smart: selected = selectContainerSmartly(valid)
        case .custom: selected = selectContainerCustomly(valid)
        }
        completion(selected, nil)
    }

    public func supportsContainerType(_ type: TFYPopupContainerType) -> Bool {
        type != .custom
    }

    public func priorityForContainer(_ containerInfo: TFYSwiftPopupContainerInfo) -> Int {
        if let calc = customPriorityCalculator { return calc(containerInfo) }
        var base = containerInfo.priority
        if preferWindowContainer, containerInfo.type == .window { base += 50 }
        if preferCurrentViewController, containerInfo.type == .viewController { base += 25 }
        return base
    }

    private func selectContainerAutomatically(_ containers: [TFYSwiftPopupContainerInfo]) -> TFYSwiftPopupContainerInfo? {
        if preferWindowContainer, let w = containers.first(where: { $0.type == .window }) { return w }
        if preferCurrentViewController, let vc = containers.first(where: { $0.type == .viewController }) { return vc }
        return containers.first { $0.type == .window }
            ?? containers.first { $0.type == .viewController }
            ?? containers.first
    }

    private func selectContainerManually(_ containers: [TFYSwiftPopupContainerInfo]) -> TFYSwiftPopupContainerInfo? {
        containers.max(by: { priorityForContainer($0) < priorityForContainer($1) })
    }

    private func selectContainerSmartly(_ containers: [TFYSwiftPopupContainerInfo]) -> TFYSwiftPopupContainerInfo? {
        containers.max(by: { calculateSmartScore($0) < calculateSmartScore($1) }) ?? containers.first
    }

    private func selectContainerCustomly(_ containers: [TFYSwiftPopupContainerInfo]) -> TFYSwiftPopupContainerInfo? {
        containers.max(by: { priorityForContainer($0) < priorityForContainer($1) })
    }

    private func calculateSmartScore(_ container: TFYSwiftPopupContainerInfo) -> Int {
        var score = container.priority
        if preferWindowContainer, container.type == .window { score += 150 }
        else if preferCurrentViewController, container.type == .viewController { score += 120 }
        else {
            switch container.type {
            case .window: score += 100
            case .viewController: score += 75
            case .view: score += 50
            case .custom: score += 25
            }
        }
        if let w = container.containerView?.window, w.isKeyWindow { score += 30 }
        if container.containerView?.window?.windowLevel == UIWindow.Level.normal { score += 20 }
        if let v = container.containerView {
            let area = v.bounds.width * v.bounds.height
            score += Int(area / 10000)
        }
        return score
    }
}
