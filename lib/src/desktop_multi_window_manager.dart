import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'multi_window_manager.dart';
import 'sub_display_state.dart';
import 'sub_window_size.dart';

/// Desktop implementation (Windows, macOS, Linux).
///
/// Each [openSubWindow] call spawns a **new OS process** running a completely
/// independent Flutter engine — there is no shared state with the main window.
///
/// ## Hot restart behaviour
/// On hot restart the Dart VM resets all static state, so [_controllers] is
/// cleared and [MultiWindowManager._instance] becomes null. The
/// [create] factory closes any sub-windows that are still alive from before
/// the restart (debug mode only), guaranteeing a clean slate.
class DesktopMultiWindowManager extends MultiWindowManager {
  DesktopMultiWindowManager._();

  /// Creates the manager and, in debug builds, closes any sub-windows that
  /// survived a hot restart so the developer always starts from a clean state.
  static Future<DesktopMultiWindowManager> create() async {
    final manager = DesktopMultiWindowManager._();
    if (kDebugMode) {
      await manager._closeStaleWindows();
    }
    return manager;
  }

  int _windowCount = 0;
  final List<WindowController> _controllers = [];

  /// Closes every sub-window that the OS still reports as alive.
  /// Called automatically by [create] in debug mode.
  Future<void> _closeStaleWindows() async {
    try {
      final ids = await DesktopMultiWindow.getAllSubWindowIds();
      for (final id in ids) {
        await WindowController.fromWindowId(id).close();
      }
    } catch (_) {
      // Not critical — ignore if the method is unavailable on this build.
    }
  }

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> openSubWindow(
    Map<String, dynamic> argument, {
    SubWindowSize size = const SubWindowSize.fullScreen(),
  }) async {
    _windowCount++;
    final controller = await DesktopMultiWindow.createWindow(
      jsonEncode({
        ...argument,
        'windowNumber': _windowCount,
        if (size.isFullScreen) '__autoMaximize': true,
      }),
    );
    await controller.setFrame(size.resolveFrame());
    await controller.setTitle('Sub Window $_windowCount');
    await controller.show();
    _controllers.add(controller);
  }

  /// No-op on desktop — state sync to a secondary display is Android-only.
  @override
  Future<void> sendStateToSubDisplay(SubDisplayState state) async {}

  @override
  Future<void> closeAll() async {
    for (final c in _controllers) {
      await c.close();
    }
    _controllers.clear();
  }
}
