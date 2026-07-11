//
//  TFYSwiftHapticFeedback.swift
//  TFYSwiftPanModel
//
//  触觉反馈工具
//

import UIKit

/// 触觉反馈工具类（按 style 缓存 generator，避免频繁分配）
public enum TFYSwiftHapticFeedback {

    private static var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let lock = NSLock()

    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        lock.lock()
        let generator: UIImpactFeedbackGenerator
        if let cached = impactGenerators[style] {
            generator = cached
        } else {
            generator = UIImpactFeedbackGenerator(style: style)
            impactGenerators[style] = generator
        }
        lock.unlock()
        generator.prepare()
        generator.impactOccurred()
    }

    public static func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }
}
