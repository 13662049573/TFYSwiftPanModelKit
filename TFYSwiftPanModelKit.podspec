Pod::Spec.new do |spec|

  spec.name         = "TFYSwiftPanModelKit"
  spec.version      = "1.1.1"
  spec.summary      = "纯 Swift 弹窗库：PanModal 半屏 + PopupView 动画弹窗 + presentPopup 控制器弹出"

  spec.description  = <<-DESC
    TFYSwiftPanModelKit 是无第三方依赖的纯 Swift iOS 弹窗组件库（iOS 15+）。

    架构分三层（可按 CocoaPods subspec 按需引入，彼此关系见下）：
    • Tools — 窗口/安全区、KVO、UIView/UIScrollView 辅助、触感反馈
    • popController — PanModal 底部半屏弹窗（依赖 Tools）
    • popView — PopupView 通用弹窗 + presentPopup（依赖 Tools）
    popController 与 popView 无交叉依赖；默认安装全部三层。

    能力概览：
    1. PanModal（popController）
       - Short / Medium / Long 多状态 + 手势拖拽
       - ScrollView 联动、自定义背景/圆角/阴影/指示器
       - ViewController 路径（presentPanModal）与纯 View 路径（ContentView.present）
    2. PopupView（popView）
       - 12 种动画、6 种布局、BottomSheet 手势面板
       - 优先级队列、容器发现、键盘避让、无障碍/暗色模式
    3. presentPopup（同属 popView）
       - 任意 UIViewController 以 PopupView 动画弹出
       - TFYSwiftPopupPresentable 配置协议 + PopupContentViewController 基类
       - TFYSwiftPopupHostingView 完整管理 child VC 生命周期
  DESC

  spec.homepage     = "https://github.com/13662049573/TFYSwiftPanModelKit"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "田风有" => "420144542@qq.com" }

  spec.platform     = :ios, "15.0"
  spec.swift_version = "5.0"

  spec.source       = { :git => "https://github.com/13662049573/TFYSwiftPanModelKit.git", :tag => "#{spec.version}" }

  spec.requires_arc = true
  spec.frameworks   = "UIKit", "Foundation"

  # ――― 子模块（与源码目录 Tools / popController / popView 一一对应）―――――――――――― #

  # 工具层 — 被 popController、popView 共同依赖；一般无需单独安装
  # 含：WindowHelper、KeyValueObserver、UIViewFrame、UIScrollViewHelper、HapticFeedback
  spec.subspec 'Tools' do |tools|
    tools.source_files = "TFYSwiftPanModelKit/TFYSwiftPanModel/Tools/**/*.swift"
  end

  # PanModal — 底部半屏弹窗（协议 / Presenter / PresentationController / 手势引擎）
  # 入口：UIViewController.presentPanModal(_:) ，或 TFYSwiftPanModalContentView.present(in:)
  # 用法：pod 'TFYSwiftPanModelKit/popController'
  spec.subspec 'popController' do |pc|
    pc.source_files = "TFYSwiftPanModelKit/TFYSwiftPanModel/popController/**/*.swift"
    pc.dependency "TFYSwiftPanModelKit/Tools"
  end

  # PopupView — 通用弹窗 + presentPopup 控制器桥接
  # 入口：TFYSwiftPopupView.show / UIViewController.presentPopup(_:)
  # 用法：pod 'TFYSwiftPanModelKit/popView'
  spec.subspec 'popView' do |pv|
    pv.source_files = "TFYSwiftPanModelKit/TFYSwiftPanModel/popView/**/*.swift"
    pv.dependency "TFYSwiftPanModelKit/Tools"
  end

  # 默认安装全部模块（等价于 pod 'TFYSwiftPanModelKit'）
  spec.default_subspecs = 'Tools', 'popController', 'popView'

end
