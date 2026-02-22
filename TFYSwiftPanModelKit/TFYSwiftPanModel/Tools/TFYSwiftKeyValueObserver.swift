//
//  TFYSwiftKeyValueObserver.swift
//  TFYSwiftPanModel
//
//  KVO 辅助工具，简化监听与回调，自动管理生命周期。由 OC KeyValueObserver 迁移。
//

import Foundation

/// KVO 监听 token，持有即保持监听，释放时自动移除
public final class TFYSwiftKeyValueObserver: NSObject {

    private weak var observedObject: NSObject?
    /// 强引用，仅用于 deinit 时安全调用 removeObserver
    private var observedObjectStrong: NSObject?
    private var keyPath: String = ""
    private var shouldObserve: Bool = true
    private var callback: (([NSKeyValueChangeKey: Any]) -> Void)?

    private override init() {
        super.init()
    }

    /// 创建 KVO 监听，自动管理移除
    /// - Parameters:
    ///   - object: 被监听对象
    ///   - keyPath: 属性路径
    ///   - options: KVO 选项
    ///   - callback: 变更回调（change 字典）
    /// - Returns: 需持有该 token，释放时自动移除监听
    public static func observe(
        _ object: NSObject,
        keyPath: String,
        options: NSKeyValueObservingOptions = [],
        callback: @escaping ([NSKeyValueChangeKey: Any]) -> Void
    ) -> TFYSwiftKeyValueObserver? {
        let observer = TFYSwiftKeyValueObserver()
        observer.keyPath = keyPath
        observer.callback = callback
        observer.observedObject = object
        observer.observedObjectStrong = object
        observer.shouldObserve = true
        object.addObserver(observer, forKeyPath: keyPath, options: options, context: Unmanaged.passUnretained(observer).toOpaque())
        return observer
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == Unmanaged.passUnretained(self).toOpaque(), let change = change else { return }
        didChange(change)
    }

    private func didChange(_ change: [NSKeyValueChangeKey: Any]) {
        guard shouldObserve else { return }
        callback?(change)
    }

    /// 取消监听（调用后需重新 observe 才生效）
    public func unobserve() {
        shouldObserve = false
    }

    deinit {
        guard let obj = observedObjectStrong, !keyPath.isEmpty else { return }
        observedObjectStrong = nil
        obj.removeObserver(self, forKeyPath: keyPath)
    }
}
