//
//  TFYSwiftUIViewFrame.swift
//  TFYSwiftPanModel
//
//  UIView frame/center/size 便捷布局扩展，由 OC UIView+TFY_Frame 迁移。
//

import UIKit

extension UIView {

    /// frame.origin.x 快捷访问/设置
    var panLeft: CGFloat {
        get { frame.origin.x }
        set {
            if frame.origin.x != newValue {
                var f = frame
                f.origin.x = newValue
                frame = f
            }
        }
    }

    /// frame.origin.y 快捷访问/设置
    var panTop: CGFloat {
        get { frame.origin.y }
        set {
            if frame.origin.y != newValue {
                var f = frame
                f.origin.y = newValue
                frame = f
            }
        }
    }

    /// frame.origin.x + frame.size.width 快捷访问/设置
    var panRight: CGFloat {
        get { frame.origin.x + frame.size.width }
        set {
            if panRight != newValue {
                var f = frame
                f.origin.x = newValue - frame.size.width
                frame = f
            }
        }
    }

    /// frame.origin.y + frame.size.height 快捷访问/设置
    var panBottom: CGFloat {
        get { frame.origin.y + frame.size.height }
        set {
            if panBottom != newValue {
                var f = frame
                f.origin.y = newValue - frame.size.height
                frame = f
            }
        }
    }

    /// frame.size.width 快捷访问/设置
    var panWidth: CGFloat {
        get { frame.size.width }
        set {
            if frame.size.width != newValue {
                var f = frame
                f.size.width = newValue
                frame = f
            }
        }
    }

    /// frame.size.height 快捷访问/设置
    var panHeight: CGFloat {
        get { frame.size.height }
        set {
            if frame.size.height != newValue {
                var f = frame
                f.size.height = newValue
                frame = f
            }
        }
    }

    /// center.x 快捷访问/设置
    var panCenterX: CGFloat {
        get { center.x }
        set {
            if center.x != newValue {
                center = CGPoint(x: newValue, y: center.y)
            }
        }
    }

    /// center.y 快捷访问/设置
    var panCenterY: CGFloat {
        get { center.y }
        set {
            if center.y != newValue {
                center = CGPoint(x: center.x, y: newValue)
            }
        }
    }

    /// frame.origin 快捷访问/设置
    var panOrigin: CGPoint {
        get { frame.origin }
        set {
            if !frame.origin.equalTo(newValue) {
                var f = frame
                f.origin = newValue
                frame = f
            }
        }
    }

    /// frame.size 快捷访问/设置
    var panSize: CGSize {
        get { frame.size }
        set {
            if !frame.size.equalTo(newValue) {
                var f = frame
                f.size = newValue
                frame = f
            }
        }
    }
}
