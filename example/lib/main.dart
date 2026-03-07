import 'dart:convert';
import 'dart:io';

import 'package:extend_screen/extend_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'main_window.dart';
import 'sub_window.dart';

/// Entry point.
///
/// On desktop the [desktop_multi_window] package re-invokes the same
/// executable with arguments ['multi_window', windowId, argumentJson] for
/// every sub-window. We detect that here and run the sub-window app instead of
/// the main app — giving each sub-window its own independent Flutter engine
/// and widget tree.
void main(List<String> args) async {
  
  WidgetsFlutterBinding.ensureInitialized();

  if (args.firstOrNull == 'multi_window') {
    // Sub-window engine: do NOT initialize window_manager here.
    // window_manager tracks the main application window (window 0). Calling
    // ensureInitialized() inside a sub-window engine retains a reference to
    // that engine, which prevents FlutterViewController.engine.shutDownEngine()
    // from being called when the sub-window is closed — leaving a zombie isolate.
    final windowId = int.parse(args[1]);
    final argument = args.length > 2 && args[2].isNotEmpty
        ? jsonDecode(args[2]) as Map<String, dynamic>
        : <String, dynamic>{};
    // Tell the manager this process is a sub-window so stale-window cleanup
    // is skipped — otherwise every sub-window would close its siblings.
    MultiWindowManager.configureAsSubWindow();
    runApp(SubWindowApp(windowId: windowId, argument: argument));
    return;
  }

  // Main window only: initialize window_manager.
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
  }
  runApp(const MainApp());
}
