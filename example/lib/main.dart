import 'dart:convert';

import 'package:flutter/material.dart';

import 'main_window.dart';
import 'sub_window.dart';

/// Entry point.
///
/// On desktop the [desktop_multi_window] package re-invokes the same
/// executable with arguments ['multi_window', windowId, argumentJson] for
/// every sub-window. We detect that here and run the sub-window app instead of
/// the main app — giving each sub-window its own independent Flutter engine
/// and widget tree.
void main(List<String> args) {
  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    final argument = args.length > 2 && args[2].isNotEmpty
        ? jsonDecode(args[2]) as Map<String, dynamic>
        : <String, dynamic>{};
    WidgetsFlutterBinding.ensureInitialized();
    runApp(SubWindowApp(windowId: windowId, argument: argument));
    return;
  }
  runApp(const MainApp());
}
