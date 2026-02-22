Pod::Spec.new do |spec|

  spec.name         = "TFYSwiftPanModelKit"
  spec.version      = "1.0.0"
  spec.summary      = "Swift PanModal 弹窗组件库，支持半屏/全屏弹窗、PopupView 动画弹窗、BottomSheet 等"

  spec.description  = <<-DESC
    TFYSwiftPanModelKit 是一个纯 Swift 弹窗组件库，提供两大核心能力：
    1. PanModal（popController）— 底部半屏弹窗，支持手势拖拽、多状态切换（Short/Medium/Long）、
       ScrollView 联动、自定义背景/圆角/阴影/拖拽指示器，同时支持 ViewController 和 View 两种展示路径。
    2. PopupView（popView）— 通用弹窗系统，内置 12 种动画效果（Fade/Zoom/Spring/Bounce/3DFlip/Rotate/Slide 等），
       支持任意方向弹出、BottomSheet 手势面板、优先级队列、容器管理等。
  DESC

  spec.homepage     = "https://github.com/13662049573/TFYSwiftPanModelKit"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "田风有" => "420144542@qq.com" }

  spec.platform     = :ios, "15.0"
  spec.swift_version = "5.0"

  spec.source       = { :git => "https://github.com/13662049573/TFYSwiftPanModelKit.git", :tag => "#{spec.version}" }

  spec.requires_arc = true
  spec.frameworks   = "UIKit", "Foundation"

  # ――― 子模块按文件夹结构拆分 ――――――――――――――――――――――――――――――――――――――――――――――――――― #

  # 工具层 — KVO 观察器、UIView/UIScrollView 扩展、窗口/浮点辅助
  spec.subspec 'Tools' do |tools|
    tools.source_files = "TFYSwiftPanModelKit/TFYSwiftPanModel/Tools/**/*.swift"
  end

  # PanModal 弹窗控制器层 — 半屏弹窗核心（协议、手势、布局、动画、Presenter）
  spec.subspec 'popController' do |pc|
    pc.source_files = "TFYSwiftPanModelKit/TFYSwiftPanModel/popController/**/*.swift"
    pc.dependency "TFYSwiftPanModelKit/Tools"
  end

  # PopupView 弹窗视图层 — 通用弹窗系统（动画器、布局、容器管理、优先级队列）
  spec.subspec 'popView' do |pv|
    pv.source_files = "TFYSwiftPanModelKit/TFYSwiftPanModel/popView/**/*.swift"
    pv.dependency "TFYSwiftPanModelKit/Tools"
  end

end
