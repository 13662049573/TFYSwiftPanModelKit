# Changelog

All notable changes to this project are documented in this file.

## [1.3.0] - 2026-10-21

### Changed

- Raised minimum deployment target from iOS 15.0 to **iOS 16.0** across Swift Package Manager, CocoaPods, and the Xcode project.
- Window and container discovery now uses `UIWindowScene.keyWindow` instead of deprecated `UIWindow.isKeyWindow`.

### Fixed

- iPad `presentPanModal` popover presentations respect `allowsDragToDismiss()` via `popoverPresentationControllerShouldDismissPopover`.

### Migration

- Apps integrating TFYSwiftPanModelKit 1.3.0 must target iOS 16.0 or later.
- For iOS 15 support, remain on the **1.2.0** release.

## [1.2.0]

Priority queue, stability, and Demo expansion. See [README](README.md#120-更新说明优先级与稳定性升级).

## [1.1.1]

`presentPopup` and hosting view controller APIs. See [README](README.md#111-更新说明控制器-popup).

## [1.0.1]

Bug fixes and feature completeness. See [README](README.md#101-更新说明功能完整性优化).
