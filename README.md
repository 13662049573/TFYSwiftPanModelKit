# TFYSwiftPanModelKit

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0"/>
  <img src="https://img.shields.io/badge/iOS-15.0%2B-blue.svg" alt="iOS 15.0+"/>
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT"/>
  <img src="https://img.shields.io/badge/CocoaPods-compatible-red.svg" alt="CocoaPods"/>
  <img src="https://img.shields.io/badge/version-1.0.0-brightgreen.svg" alt="version"/>
</p>

<p align="center">
  <b>纯 Swift 弹窗组件库 — PanModal 半屏弹窗 + PopupView 动画弹窗，一站式解决 iOS 弹窗需求</b>
</p>

---

## 功能概览

TFYSwiftPanModelKit 提供两大核心模块，覆盖 iOS 开发中常见的所有弹窗场景：

| 模块 | 能力 | 场景 |
|------|------|------|
| **PanModal** | 底部半屏弹窗，支持手势拖拽、多状态切换、ScrollView 联动 | 分享面板、评论区、筛选器、地址选择 |
| **PopupView** | 通用弹窗，12 种动画，任意方向弹出，BottomSheet 手势面板 | Alert、Toast、侧边栏、操作菜单、广告弹窗 |

---

## 核心特性

**PanModal 弹窗**
- Short / Medium / Long 三种高度状态，手势拖拽平滑切换
- 支持 ViewController 和 View 两种展示路径（有 VC 或无 VC 均可）
- 内置 ScrollView 联动 — 列表滚动到顶部时自动切换为弹窗拖拽
- 自定义背景遮罩（纯色 / 系统模糊 / 自定义模糊）
- 自定义圆角、阴影、拖拽指示器
- 键盘自适应、防频繁点击保护
- 完整的生命周期回调

**PopupView 弹窗**
- 12 种内置动画：Fade、Zoom、Spring、Bounce、3D Flip、Rotate、4 方向 Slide、BottomSheet
- 6 种布局位置：居中、顶部、底部、左侧、右侧、自定义 Frame
- BottomSheet 支持拖拽调整高度、速度感应关闭
- 优先级队列管理（Background → Low → Normal → High → Critical → Urgent）
- 点击背景自动关闭
- 完整的 delegate 生命周期

---

## 安装

### CocoaPods

```ruby
# 安装全部模块
pod 'TFYSwiftPanModelKit'

# 或按需安装
pod 'TFYSwiftPanModelKit/popController'  # 仅 PanModal
pod 'TFYSwiftPanModelKit/popView'        # 仅 PopupView
```

### 手动安装

将 `TFYSwiftPanModelKit/TFYSwiftPanModel/` 文件夹拖入 Xcode 项目即可。

---

## 快速上手

### 1. PanModal — 底部半屏弹窗（ViewController 方式）

只需 3 步：创建 VC、重写高度方法、调用 `presentPanModal`。

```swift
class MySheetViewController: UIViewController {

    override func shortFormHeight() -> PanModalHeight {
        PanModalHeight(type: .content, height: 300)
    }

    override func longFormHeight() -> PanModalHeight {
        PanModalHeight(type: .max, height: 0)  // 全屏
    }

    override func originPresentationState() -> PresentationState {
        .short  // 首次弹出为半屏
    }
}

// 展示弹窗 — 任何 UIViewController 都可以调用
presentPanModal(MySheetViewController())
```

### 2. PanModal — 底部弹窗（纯 View 方式，无需 VC）

```swift
let contentView = TFYSwiftPanModalContentView(frame: .zero)
contentView.backgroundColor = .systemBackground
// ... 添加自定义子视图 ...

// 直接在 window 上展示
contentView.present(in: view.window)

// 关闭
contentView.dismiss(animated: true, completion: nil)
```

### 3. PopupView — 居中弹窗（各种动画）

```swift
let popup = TFYSwiftPopupView(frame: .zero)
popup.backgroundColor = .systemBackground
popup.layer.cornerRadius = 16
// ... 添加自定义子视图 ...

// 选择动画器（12 种可选）
let animator = TFYSwiftPopupSpringAnimator()
let center = TFYSwiftPopupAnimatorLayoutCenter.layout(
    offsetY: 0, offsetX: 0, width: 300, height: 220
)
animator.layout = TFYSwiftPopupAnimatorLayout.center(center)

// 展示
popup.show(in: window, animator: animator)

// 关闭
popup.dismissAnimated(true)
```

### 4. PopupView — 方向滑入弹窗

```swift
let popup = TFYSwiftPopupView(frame: .zero)
popup.backgroundColor = .systemBackground

// 从底部滑入，全宽，高度 250
let bottom = TFYSwiftPopupAnimatorLayoutBottom.layout(
    bottomMargin: 0, offsetX: 0, height: 250
)
let animator = TFYSwiftPopupSlideAnimator(
    direction: .fromBottom,
    layout: TFYSwiftPopupAnimatorLayout.bottom(bottom)
)

popup.show(in: window, animator: animator)
```

支持四个方向：`.fromTop` / `.fromBottom` / `.fromLeft` / `.fromRight`

### 5. PopupView — BottomSheet 手势面板

```swift
let config = TFYSwiftPopupBottomSheetConfiguration()
config.defaultHeight = 350
config.enableGestures = true        // 开启拖拽手势
config.cornerRadius = 16
config.allowsFullScreen = true      // 允许上拉全屏

let animator = TFYSwiftPopupBottomSheetAnimator(configuration: config)
let popup = TFYSwiftPopupView(frame: .zero)
// ... 添加内容 ...

popup.show(in: window, animator: animator)
```

---

## PanModal 高级配置

所有配置通过重写 `UIViewController` 方法实现，每个方法都有合理的默认值：

```swift
class AdvancedSheetVC: UIViewController {

    // MARK: - 高度
    override func shortFormHeight() -> PanModalHeight {
        PanModalHeight(type: .content, height: 300)
    }
    override func mediumFormHeight() -> PanModalHeight {
        PanModalHeight(type: .content, height: 500)
    }
    override func longFormHeight() -> PanModalHeight {
        PanModalHeight(type: .max, height: 0)
    }

    // MARK: - ScrollView 联动
    override func panScrollable() -> UIScrollView? { tableView }

    // MARK: - 背景
    override func backgroundConfig() -> TFYSwiftBackgroundConfig {
        let config = TFYSwiftBackgroundConfig.config(behavior: .customBlurEffect)
        config.backgroundAlpha = 0.6
        config.backgroundBlurRadius = 15
        return config
    }

    // MARK: - 外观
    override func cornerRadius() -> CGFloat { 20 }
    override func contentShadow() -> TFYSwiftPanModalShadow {
        TFYSwiftPanModalShadow(
            color: .black.withAlphaComponent(0.3),
            radius: 12,
            offset: CGSize(width: 0, height: -4),
            opacity: 0.4
        )
    }

    // MARK: - 交互
    override func allowsDragToDismiss() -> Bool { true }
    override func allowsTapBackgroundToDismiss() -> Bool { true }
    override func springDamping() -> CGFloat { 0.8 }
}
```

### 可配置项一览

| 类别 | 方法 | 默认值 | 说明 |
|------|------|--------|------|
| **高度** | `shortFormHeight()` | longFormHeight | 短状态高度 |
| | `mediumFormHeight()` | longFormHeight | 中等状态高度 |
| | `longFormHeight()` | .max (全屏) | 长状态高度 |
| | `originPresentationState()` | .short | 初始状态 |
| **滚动** | `panScrollable()` | nil | 关联的 ScrollView |
| | `isPanScrollEnabled()` | true | 是否允许内部滚动 |
| **背景** | `backgroundConfig()` | .default | 背景样式配置 |
| **外观** | `cornerRadius()` | 8 | 顶部圆角 |
| | `contentShadow()` | .none | 阴影配置 |
| | `showDragIndicator()` | true | 是否显示拖拽指示器 |
| **交互** | `allowsDragToDismiss()` | true | 是否允许下拉关闭 |
| | `allowsTapBackgroundToDismiss()` | true | 是否允许点击背景关闭 |
| | `allowScreenEdgeInteractive()` | false | 是否允许边缘滑动关闭 |
| **动画** | `springDamping()` | 0.8 | 弹簧阻尼 |
| | `transitionDuration()` | 0.5 | 弹出动画时长 |
| | `dismissalDuration()` | 0.5 | 关闭动画时长 |
| **键盘** | `isAutoHandleKeyboardEnabled()` | true | 自动处理键盘 |
| **安全** | `shouldPreventFrequentTapping()` | true | 防频繁点击 |

---

## PopupView 动画器

### 内置 12 种动画

| 动画 | 类名 | 效果 |
|------|------|------|
| 渐变 | `TFYSwiftPopupFadeInOutAnimator` | 透明度渐入渐出 |
| 缩放 | `TFYSwiftPopupZoomInOutAnimator` | 从 0.3x 缩放至 1x |
| 弹簧 | `TFYSwiftPopupSpringAnimator` | 弹簧回弹效果 |
| 弹跳 | `TFYSwiftPopupBounceAnimator` | 从极小弹跳放大 |
| 3D翻转 | `TFYSwiftPopup3DFlipAnimator` | Y 轴 3D 翻转（带透视） |
| 旋转 | `TFYSwiftPopupRotateAnimator` | 180 度旋转 |
| 上滑 | `TFYSwiftPopupSlideAnimator(.fromBottom)` | 从底部滑入 |
| 下滑 | `TFYSwiftPopupSlideAnimator(.fromTop)` | 从顶部滑入 |
| 左滑 | `TFYSwiftPopupSlideAnimator(.fromLeft)` | 从左侧滑入 |
| 右滑 | `TFYSwiftPopupSlideAnimator(.fromRight)` | 从右侧滑入 |
| 方向动画 | `TFYSwiftPopupUpward/Downward/Leftward/RightwardAnimator` | 指定方向平移 |
| 底部面板 | `TFYSwiftPopupBottomSheetAnimator` | 底部弹出+手势拖拽 |

### 6 种布局位置

```swift
// 居中
TFYSwiftPopupAnimatorLayout.center(
    TFYSwiftPopupAnimatorLayoutCenter.layout(offsetY: 0, offsetX: 0, width: 300, height: 200)
)

// 顶部
TFYSwiftPopupAnimatorLayout.top(
    TFYSwiftPopupAnimatorLayoutTop.layout(topMargin: 0, offsetX: 0, height: 250)
)

// 底部
TFYSwiftPopupAnimatorLayout.bottom(
    TFYSwiftPopupAnimatorLayoutBottom.layout(bottomMargin: 0, offsetX: 0, height: 250)
)

// 左侧
TFYSwiftPopupAnimatorLayout.leading(
    TFYSwiftPopupAnimatorLayoutLeading.layout(leadingMargin: 0, offsetY: 0, width: 280)
)

// 右侧
TFYSwiftPopupAnimatorLayout.trailing(
    TFYSwiftPopupAnimatorLayoutTrailing.layout(trailingMargin: 0, offsetY: 0, width: 280)
)

// 自定义 Frame
TFYSwiftPopupAnimatorLayout.frame(CGRect(x: 50, y: 100, width: 300, height: 200))
```

### PopupView 生命周期

```swift
class MyPopupDelegate: TFYSwiftPopupViewDelegate {
    func popupViewWillAppear(_ popupView: TFYSwiftPopupView) { }
    func popupViewDidAppear(_ popupView: TFYSwiftPopupView) { }
    func popupViewWillDisappear(_ popupView: TFYSwiftPopupView) { }
    func popupViewDidDisappear(_ popupView: TFYSwiftPopupView) { }
    func popupViewShouldDismiss(_ popupView: TFYSwiftPopupView) -> Bool { true }
    func popupViewDidTapBackground(_ popupView: TFYSwiftPopupView) { }
}
```

---

## 项目结构

```
TFYSwiftPanModel/
├── Tools/                          # 工具层
│   ├── TFYSwiftKeyValueObserver    # KVO 安全观察器
│   ├── TFYSwiftUIViewFrame         # UIView frame 便捷扩展
│   ├── TFYSwiftUIScrollViewHelper  # UIScrollView 滚动状态
│   └── TFYSwiftWindowHelper        # 全局窗口/安全区域工具
│
├── popController/                  # PanModal 弹窗控制器（28 个文件）
│   ├── Protocol
│   │   ├── TFYSwiftPanModalPresentable           # 核心配置协议（40+ 可选配置）
│   │   ├── TFYSwiftPanModalPresenterProtocol      # Presenter 协议
│   │   ├── TFYSwiftPanModalPanGestureDelegate     # 手势代理
│   │   └── TFYSwiftPanModalIndicatorProtocol      # 拖拽指示器协议
│   ├── ViewController Path
│   │   ├── TFYSwiftPanModalPresentationController # UIPresentationController 实现
│   │   ├── TFYSwiftPanModalPresentationAnimator   # 转场动画（底部滑入/滑出）
│   │   ├── TFYSwiftPanModalPresentationDelegate   # UIViewControllerTransitioningDelegate
│   │   └── TFYSwiftUIViewControllerPanModal*      # UIViewController 扩展
│   ├── View Path
│   │   ├── TFYSwiftPanModalContentView            # View 弹窗（无需 VC）
│   │   └── TFYSwiftPanModalContainerView          # View 弹窗容器
│   ├── Core
│   │   ├── TFYSwiftPanModalPresentableHandler     # 手势/状态/键盘核心引擎
│   │   ├── TFYSwiftPanModalAnimator               # 弹簧动画工具
│   │   └── TFYSwiftPanModalHeight                 # 高度类型定义
│   └── UI
│       ├── TFYSwiftDimmedView                     # 背景遮罩/模糊
│       ├── TFYSwiftPanContainerView               # 内容容器+阴影
│       ├── TFYSwiftPanIndicatorView               # 默认拖拽指示器
│       └── TFYSwiftVisualEffectView               # 自定义模糊视图
│
└── popView/                        # PopupView 弹窗视图（14 个文件）
    ├── Core
    │   ├── TFYSwiftPopupView                      # 弹窗核心（show/dismiss 生命周期）
    │   ├── TFYSwiftPopupViewAnimator              # 动画器协议
    │   └── TFYSwiftPopupViewDelegate              # 生命周期代理
    ├── Animator
    │   ├── TFYSwiftPopupBaseAnimator              # 动画器基类（布局+动画执行）
    │   ├── TFYSwiftPopupAnimators                 # 12 种内置动画
    │   ├── TFYSwiftPopupAnimatorLayout            # 6 种布局配置
    │   └── TFYSwiftPopupBottomSheetAnimator       # BottomSheet 手势面板
    ├── Config
    │   ├── TFYSwiftPopupViewConfiguration         # 弹窗全局配置
    │   ├── TFYSwiftPopupKeyboardConfiguration     # 键盘配置
    │   └── TFYSwiftPopupContainerConfiguration    # 容器尺寸配置
    ├── Container
    │   ├── TFYSwiftPopupContainerType             # 容器类型+选择器
    │   ├── TFYSwiftPopupContainerManager          # 容器自动发现管理
    │   └── TFYSwiftPopupBackgroundView            # 背景视图（纯色/模糊/渐变）
    └── Priority
        └── TFYSwiftPopupPriorityManager           # 优先级队列管理
```

---

## 系统要求

| 项目 | 要求 |
|------|------|
| iOS | 15.0+ |
| Swift | 5.0+ |
| Xcode | 15.0+ |
| 依赖 | 无第三方依赖 |

---

## 许可证

TFYSwiftPanModelKit 基于 MIT 许可证发布。详见 [LICENSE](LICENSE) 文件。

---

## 作者

**田风有** — 420144542@qq.com

如果这个库对你有帮助，欢迎 Star 支持！
